using System.Diagnostics;
using System.Text.Json;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using LongEva.Api;
using Microsoft.AspNetCore.Http.Features;

var builder = WebApplication.CreateBuilder(args);
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase);
builder.Services.AddHttpClient<GeminiService>();
builder.Services.AddHttpClient<IMealImageStorage, CloudinaryImageService>();
builder.Services.ConfigureHttpClientDefaults(options =>
    options.ConfigureHttpClient(client => client.Timeout = TimeSpan.FromSeconds(30)));
builder.Services.Configure<FormOptions>(options => options.MultipartBodyLengthLimit = 10 * 1024 * 1024 + 1024 * 1024);
builder.Services.AddSingleton<FirebaseTokenVerifier>();
builder.Services.AddSingleton<GeminiService>();
builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseCors();
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapPost("/api/meal-images", async (HttpRequest request, FirebaseTokenVerifier tokens, IMealImageStorage storage, CancellationToken cancellationToken) =>
{
    if (await tokens.VerifyAsync(request, cancellationToken) is null) return Results.Unauthorized();
    if (!request.HasFormContentType) return Results.BadRequest(new { error = "Expected multipart form data." });
    var form = await request.ReadFormAsync(cancellationToken);
    var file = form.Files.GetFile("image");
    if (file is null || file.Length == 0 || file.Length > 10 * 1024 * 1024)
        return Results.BadRequest(new { error = "Image must be between 1 byte and 10 MB." });
    await using var buffer = new MemoryStream();
    await file.CopyToAsync(buffer, cancellationToken);
    var bytes = buffer.ToArray();
    var type = ImageValidation.Detect(bytes);
    if (type is null) return Results.BadRequest(new { error = "Only JPEG, PNG and WebP images are supported." });
    try
    {
        return Results.Ok(await storage.UploadAsync(bytes, type, cancellationToken));
    }
    catch (InvalidOperationException)
    {
        return Results.Problem("Image storage is not configured.", statusCode: 503);
    }
    catch (HttpRequestException)
    {
        return Results.Problem("Image storage is unavailable.", statusCode: 502);
    }
}).WithName("UploadMealImage").WithSummary("Upload an authenticated user's meal image.");

app.MapPost("/api/ai/meal-recommendations", async (
    RecommendationRequest request,
    HttpRequest httpRequest,
    FirebaseTokenVerifier tokens,
    GeminiService ai,
    ILogger<Program> logger,
    CancellationToken cancellationToken) =>
{
    var correlationId = httpRequest.Headers["X-Correlation-ID"].FirstOrDefault() ?? Guid.NewGuid().ToString("N");
    logger.LogInformation("[{CorrelationId}] POST /api/ai/meal-recommendations received for mealType={MealType}, targetAgeGroup={TargetAgeGroup}",
        correlationId, request.MealType, request.TargetAgeGroup ?? request.Profile?.AgeGroup);

    var auth = await tokens.VerifyAsync(httpRequest, cancellationToken);
    if (auth is null)
    {
        logger.LogWarning("[{CorrelationId}] Unauthorized request to /api/ai/meal-recommendations", correlationId);
        return Results.Unauthorized();
    }

    if (request.Profile is null)
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: profile is required.", correlationId);
        return Results.BadRequest(new { error = "profile is required.", correlationId });
    }
    if (string.IsNullOrWhiteSpace(request.MealType))
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: mealType is required.", correlationId);
        return Results.BadRequest(new { error = "mealType is required.", correlationId });
    }
    if (request.Catalog is null || request.Catalog.Count == 0)
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: catalog is required and must not be empty.", correlationId);
        return Results.BadRequest(new { error = "catalog is required and must not be empty.", correlationId });
    }

    try
    {
        var result = await ai.RecommendAsync(request, cancellationToken);
        logger.LogInformation("[{CorrelationId}] Recommendation generated successfully (HTTP 200)", correlationId);
        return Results.Ok(result);
    }
    catch (AiConfigurationException ex)
    {
        logger.LogError(ex, "[{CorrelationId}] AI configuration error: {Message} (HTTP 503)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (AiUnavailableException ex)
    {
        logger.LogWarning(ex, "[{CorrelationId}] AI temporarily unavailable", correlationId);
        httpRequest.HttpContext.Response.Headers.RetryAfter = "10";
        return Results.Problem("Dịch vụ AI đang quá tải hoặc tạm thời không kết nối được. Hãy thử lại sau ít phút.",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (AiRateLimitException ex)
    {
        logger.LogWarning(ex, "[{CorrelationId}] AI rate limit reached: {Message} (HTTP 429)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status429TooManyRequests);
    }
    catch (AiProviderException ex)
    {
        logger.LogError(ex, "[{CorrelationId}] AI provider error: {Message} (HTTP 502)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status502BadGateway);
    }
});

app.MapPost("/api/ai/meal-evaluation", async (
    HttpRequest httpRequest,
    FirebaseTokenVerifier tokens,
    GeminiService ai,
    ILogger<Program> logger,
    CancellationToken cancellationToken) =>
{
    var correlationId = httpRequest.Headers["X-Correlation-ID"].FirstOrDefault() ?? Guid.NewGuid().ToString("N");
    logger.LogInformation("[{CorrelationId}] POST /api/ai/meal-evaluation received", correlationId);

    var auth = await tokens.VerifyAsync(httpRequest, cancellationToken);
    if (auth is null)
    {
        logger.LogWarning("[{CorrelationId}] Unauthorized request to /api/ai/meal-evaluation", correlationId);
        return Results.Unauthorized();
    }
    if (!httpRequest.HasFormContentType)
    {
        logger.LogWarning("[{CorrelationId}] Invalid content type: multipart/form-data required", correlationId);
        return Results.BadRequest(new { error = "multipart/form-data is required.", correlationId });
    }

    var form = await httpRequest.ReadFormAsync(cancellationToken);
    var image = form.Files.GetFile("image");
    if (image is null || image.Length == 0)
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: image is required", correlationId);
        return Results.BadRequest(new { error = "image is required.", correlationId });
    }
    if (image.Length > 10 * 1024 * 1024)
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: image exceeds 10 MB", correlationId);
        return Results.BadRequest(new { error = "image must be 10 MB or smaller.", correlationId });
    }

    await using var stream = image.OpenReadStream();
    using var memory = new MemoryStream();
    await stream.CopyToAsync(memory, cancellationToken);
    var contentType = ImageValidation.Detect(
        memory.GetBuffer().AsSpan(0, checked((int)memory.Length)));
    if (contentType is null)
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: image content does not match declared format", correlationId);
        return Results.BadRequest(new { error = "The image content does not match its declared format.", correlationId });
    }

    var confirmed = ParseCatalog(form["confirmedFoods"].ToString());
    var catalog = ParseCatalog(form["catalog"].ToString());

    var request = new EvaluationRequest(
        form["mealType"].ToString(),
        form["profile"].ToString(),
        form["notes"].ToString(),
        form["principles"].ToString(),
        catalog,
        confirmed.Count > 0 ? confirmed : null,
        contentType,
        memory.ToArray());

    try
    {
        var result = await ai.EvaluateAsync(request, cancellationToken);
        logger.LogInformation("[{CorrelationId}] Meal evaluated successfully (HTTP 200)", correlationId);
        return Results.Ok(result);
    }
    catch (AiConfigurationException ex)
    {
        logger.LogError(ex, "[{CorrelationId}] AI configuration error: {Message} (HTTP 503)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (AiUnavailableException ex)
    {
        logger.LogWarning(ex, "[{CorrelationId}] AI temporarily unavailable", correlationId);
        httpRequest.HttpContext.Response.Headers.RetryAfter = "10";
        return Results.Problem("Dịch vụ AI đang quá tải hoặc tạm thời không kết nối được. Hãy thử lại sau ít phút.",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (AiRateLimitException ex)
    {
        logger.LogWarning(ex, "[{CorrelationId}] AI rate limit reached: {Message} (HTTP 429)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status429TooManyRequests);
    }
    catch (AiProviderException ex)
    {
        logger.LogError(ex, "[{CorrelationId}] AI provider error: {Message} (HTTP 502)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status502BadGateway);
    }
});

app.MapPost("/api/ai/meal-evaluation/manual", async (
    ManualEvaluationRequest request,
    HttpRequest httpRequest,
    FirebaseTokenVerifier tokens,
    GeminiService ai,
    ILogger<Program> logger,
    CancellationToken cancellationToken) =>
{
    var correlationId = httpRequest.Headers["X-Correlation-ID"].FirstOrDefault() ?? Guid.NewGuid().ToString("N");
    logger.LogInformation("[{CorrelationId}] POST /api/ai/meal-evaluation/manual received for mealType={MealType}, itemsCount={Count}",
        correlationId, request.MealType, request.ConfirmedFoods?.Count ?? 0);

    var auth = await tokens.VerifyAsync(httpRequest, cancellationToken);
    if (auth is null)
    {
        logger.LogWarning("[{CorrelationId}] Unauthorized request to /api/ai/meal-evaluation/manual", correlationId);
        return Results.Unauthorized();
    }
    if (string.IsNullOrWhiteSpace(request.MealType) ||
        request.ConfirmedFoods is null || request.ConfirmedFoods.Count == 0)
    {
        logger.LogWarning("[{CorrelationId}] Validation failed: mealType and confirmedFoods are required", correlationId);
        return Results.BadRequest(new { error = "mealType and confirmedFoods are required.", correlationId });
    }

    try
    {
        var evaluation = new EvaluationRequest(
            request.MealType,
            request.Profile ?? string.Empty,
            request.Notes ?? string.Empty,
            request.Principles ?? string.Empty,
            request.ConfirmedFoods,
            request.ConfirmedFoods);
        var result = await ai.EvaluateAsync(evaluation, cancellationToken);
        logger.LogInformation("[{CorrelationId}] Manual meal evaluation succeeded (HTTP 200)", correlationId);
        return Results.Ok(result);
    }
    catch (AiConfigurationException ex)
    {
        logger.LogError(ex, "[{CorrelationId}] AI configuration error: {Message} (HTTP 503)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (AiUnavailableException ex)
    {
        logger.LogWarning(ex, "[{CorrelationId}] AI temporarily unavailable", correlationId);
        httpRequest.HttpContext.Response.Headers.RetryAfter = "10";
        return Results.Problem("Dịch vụ AI đang quá tải hoặc tạm thời không kết nối được. Hãy thử lại sau ít phút.",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
    catch (AiRateLimitException ex)
    {
        logger.LogWarning(ex, "[{CorrelationId}] AI rate limit reached: {Message} (HTTP 429)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status429TooManyRequests);
    }
    catch (AiProviderException ex)
    {
        logger.LogError(ex, "[{CorrelationId}] AI provider error: {Message} (HTTP 502)", correlationId, ex.Message);
        return Results.Problem(ex.Message, statusCode: StatusCodes.Status502BadGateway);
    }
});

app.Run();

static IReadOnlyList<CatalogFood> ParseCatalog(string value)
{
    if (string.IsNullOrWhiteSpace(value)) return [];
    try
    {
        return JsonSerializer.Deserialize<List<CatalogFood>>(value,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? [];
    }
    catch (JsonException)
    {
        return [];
    }
}

static class ImageValidation
{
    public static string? Detect(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length >= 3 && bytes[..3].SequenceEqual(new byte[] { 0xff, 0xd8, 0xff }))
            return "image/jpeg";
        if (bytes.Length >= 8 && bytes[..8].SequenceEqual(new byte[] { 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a }))
            return "image/png";
        if (bytes.Length >= 12 && bytes[..4].SequenceEqual("RIFF"u8) &&
            bytes[8..12].SequenceEqual("WEBP"u8))
            return "image/webp";
        return null;
    }
}

public partial class Program { }
