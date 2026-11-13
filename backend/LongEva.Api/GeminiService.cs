using System.Net;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace LongEva.Api;

public sealed class GeminiService
{
    private readonly HttpClient _http;
    private readonly IConfiguration _configuration;
    private readonly ILogger<GeminiService> _logger;

    public GeminiService(
        HttpClient http,
        IConfiguration configuration,
        ILogger<GeminiService> logger)
    {
        _http = http;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<JsonElement> RecommendAsync(
        RecommendationRequest request,
        CancellationToken cancellationToken)
    {
        var catalog = request.Catalog.Where(food =>
            (request.MealType == "day" || food.Category == request.MealType) &&
            (food.AgeGroups is not { Count: > 0 } ||
                food.AgeGroups.Contains(request.TargetAgeGroup ?? request.Profile?.AgeGroup ?? "")) &&
            CatalogPolicy.Allows(food, request.Profile)).ToList();
        if (catalog.Count == 0)
            return JsonSerializer.SerializeToElement(new { recommendations = Array.Empty<object>(), missingData = new[] { "Không có món phù hợp trong danh mục." } });
        var result = await GenerateJsonAsync(BuildRecommendationPrompt(request with { Catalog = catalog }), null, cancellationToken);
        if (result.ValueKind != JsonValueKind.Object)
            throw new AiProviderException("AI returned an invalid recommendation object.");
        var output = JsonNode.Parse(result.GetRawText())!.AsObject();
        if (output["recommendations"] is not JsonArray recommendations)
            throw new AiProviderException("AI returned no recommendation list.");
        var valid = new JsonArray();
        foreach (var item in recommendations.OfType<JsonObject>())
        {
            var food = catalog.FirstOrDefault(food => food.Id == item["catalogId"]?.ToString());
            if (food is null) continue;
            var copy = item.DeepClone().AsObject();
            copy["mealName"] = food.Name;
            copy["alternatives"] = JsonSerializer.SerializeToNode(
                (item["alternatives"] as JsonArray ?? new JsonArray()).Select(id => id?.ToString())
                    .Where(id => id != food.Id && catalog.Any(candidate => candidate.Id == id)).Distinct());
            valid.Add(copy);
        }
        if (valid.Count == 0 && recommendations.Count > 0)
            throw new AiProviderException("AI recommendations did not match the allowed catalog.");
        output["recommendations"] = valid;
        output["ageGroup"] = request.TargetAgeGroup ?? request.Profile?.AgeGroup;
        return JsonSerializer.SerializeToElement(output);
    }

    public async Task<JsonElement> EvaluateAsync(
        EvaluationRequest request,
        CancellationToken cancellationToken)
    {
        var result = await GenerateJsonAsync(
            BuildEvaluationPrompt(request),
            request.MimeType is not null && request.ImageBytes is not null
                ? new InlineImage(request.MimeType, request.ImageBytes)
                : null,
            cancellationToken);
        return NormalizeEvaluation(result, request.ConfirmedFoods);
    }

    public static JsonElement NormalizeEvaluation(JsonElement result, IReadOnlyList<CatalogFood>? confirmedFoods)
    {
        if (result.ValueKind != JsonValueKind.Object)
            throw new AiProviderException("AI returned an invalid evaluation object.");
        var output = JsonNode.Parse(result.GetRawText())!.AsObject();
        // A manual evaluation always preserves exactly the confirmed list.
        if (confirmedFoods is not null)
            output["recognizedFoods"] = JsonSerializer.SerializeToNode(confirmedFoods.Select(food => new {
                name = food.Name, catalogId = food.Id, confirmedByUser = true,
                needsConfirmation = false, source = "USER_CONFIRMED"
            }));
        var supplied = output["principleAnalyses"] ?? output["criteriaResults"];
        var criteria = new JsonArray();
        var seen = new HashSet<string>();
        foreach (var node in supplied as JsonArray ?? new JsonArray())
        {
            if (node is not JsonObject item) continue;
            var id = item["principleId"]?.ToString();
            var principle = VerifiedBook.Principles.FirstOrDefault(p => p.GetProperty("id").GetString() == id);
            if (principle.ValueKind == JsonValueKind.Undefined || !seen.Add(id!)) continue;
            var status = item["status"]?.ToString().ToUpperInvariant();
            criteria.Add(new JsonObject {
                ["principleId"] = id,
                ["principleName"] = principle.GetProperty("name").GetString(),
                ["sourceType"] = "BOOK_VERIFIED",
                ["sourceChapter"] = principle.GetProperty("sourceChapter").GetString(),
                ["sourcePage"] = principle.GetProperty("sourcePage").GetInt32(),
                ["sourcePdfPage"] = principle.GetProperty("sourcePdfPage").GetInt32(),
                ["status"] = status is "MATCH" or "PARTIAL" or "NOT_MATCH" ? status : "INSUFFICIENT_DATA",
                ["reason"] = item["reason"]?.ToString() ?? item["assessment"]?.ToString() ?? "Chưa đủ dữ liệu."
            });
        }
        output["principleAnalyses"] = criteria;
        foreach (var principle in VerifiedBook.Principles)
        {
            var id = principle.GetProperty("id").GetString()!;
            if (seen.Contains(id)) continue;
            criteria.Add(new JsonObject {
                ["principleId"] = id,
                ["principleName"] = principle.GetProperty("name").GetString(),
                ["sourceType"] = "BOOK_VERIFIED",
                ["sourceChapter"] = principle.GetProperty("sourceChapter").GetString(),
                ["sourcePage"] = principle.GetProperty("sourcePage").GetInt32(),
                ["sourcePdfPage"] = principle.GetProperty("sourcePdfPage").GetInt32(),
                ["status"] = "INSUFFICIENT_DATA",
                ["reason"] = "AI chưa cung cấp đủ dữ liệu để đối chiếu tiêu chí này."
            });
        }
        output.Remove("criteriaResults");
        foreach (var key in new[] { "score", "totalScore", "fitScore", "maxScore" }) output.Remove(key);
        output["references"] = JsonSerializer.SerializeToNode(criteria.OfType<JsonObject>().Select(c =>
            $"The Longevity Diet — {c["sourceChapter"]}, trang in {c["sourcePage"]} (longo.pdf, trang PDF {c["sourcePdfPage"]})").Distinct());
        return JsonSerializer.SerializeToElement(output);
    }

    private async Task<JsonElement> GenerateJsonAsync(
        string prompt,
        InlineImage? image,
        CancellationToken cancellationToken)
    {
        using var budget = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        budget.CancelAfter(TimeSpan.FromSeconds(24));
        try
        {
            return await GenerateWithFallbackAsync(prompt, image, budget.Token);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new AiUnavailableException("AI request exceeded its time budget.");
        }
    }

    private async Task<JsonElement> GenerateWithFallbackAsync(string prompt, InlineImage? image, CancellationToken cancellationToken)
    {
        try
        {
            var result = await GenerateGeminiAsync(prompt, image, cancellationToken);
            _logger.LogInformation("Gemini provider completed the AI request.");
            return result;
        }
        catch (AiConfigurationException)
        {
            throw;
        }
        catch (AiUnavailableException ex) when (HasGroqKey())
        {
            return await TryGroqAsync(prompt, image, ex.Message, cancellationToken);
        }
        catch (AiRateLimitException ex) when (HasGroqKey())
        {
            return await TryGroqAsync(prompt, image, ex.Message, cancellationToken);
        }
        catch (AiProviderException ex) when (HasGroqKey())
        {
            return await TryGroqAsync(prompt, image, ex.Message, cancellationToken);
        }
    }

    private bool HasGroqKey() => !string.IsNullOrWhiteSpace(
        _configuration["Groq:ApiKey"] ?? Environment.GetEnvironmentVariable("GROQ_API_KEY"));

    private async Task<JsonElement> GenerateGeminiAsync(string prompt, InlineImage? image, CancellationToken cancellationToken)
    {
        for (var attempt = 0; ; attempt++)
        {
            try { return await SendGeminiAsync(prompt, image, cancellationToken); }
            catch (AiUnavailableException) when (attempt < 2)
            {
                _logger.LogWarning("Gemini temporarily unavailable; retry {Attempt}/2.", attempt + 1);
                await Task.Delay(TimeSpan.FromMilliseconds(500 * (attempt + 1)), cancellationToken);
            }
        }
    }

    private async Task<JsonElement> SendGeminiAsync(
        string prompt,
        InlineImage? image,
        CancellationToken cancellationToken)
    {
        var key = _configuration["GEMINI_API_KEY"] ??
            Environment.GetEnvironmentVariable("GEMINI_API_KEY");
        if (string.IsNullOrWhiteSpace(key))
            throw new AiConfigurationException(
                "GEMINI_API_KEY is not configured on the backend.");

        var model = _configuration["GEMINI_MODEL"] ??
            Environment.GetEnvironmentVariable("GEMINI_MODEL") ??
            "gemini-2.5-flash";
        var endpoint = _configuration["GEMINI_ENDPOINT"] ??
            Environment.GetEnvironmentVariable("GEMINI_ENDPOINT") ??
            "https://generativelanguage.googleapis.com/v1beta/models";
        var url = $"{endpoint.TrimEnd('/')}/{Uri.EscapeDataString(model)}:generateContent";
        var parts = new List<object> { new { text = prompt } };
        if (image is not null)
        {
            parts.Add(new
            {
                inline_data = new
                {
                    mime_type = image.MimeType,
                    data = Convert.ToBase64String(image.Bytes)
                }
            });
        }

        using var content = new StringContent(JsonSerializer.Serialize(new
        {
            contents = new[] { new { role = "user", parts } },
            generationConfig = new
            {
                temperature = 0.1,
                responseMimeType = "application/json"
            }
        }), Encoding.UTF8, "application/json");
        HttpResponseMessage response;
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, url);
            request.Headers.Add("x-goog-api-key", key);
            request.Content = content;
            response = await _http.SendAsync(request, cancellationToken);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new AiUnavailableException("Gemini request timed out.");
        }
        catch (HttpRequestException)
        {
            throw new AiUnavailableException("Gemini connection failed.");
        }
        using var responseLifetime = response;
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            if (response.StatusCode is HttpStatusCode.ServiceUnavailable or HttpStatusCode.BadGateway or HttpStatusCode.GatewayTimeout)
                throw new AiUnavailableException($"Gemini temporarily unavailable (HTTP {(int)response.StatusCode}).");
            var detail = ExtractProviderError(body);
            if (response.StatusCode == HttpStatusCode.TooManyRequests)
                throw new AiRateLimitException(
                    $"Gemini rate limit reached for model '{model}'. Please try again later.");
            throw new AiProviderException(
                $"Gemini request failed with HTTP {(int)response.StatusCode} using model '{model}': {detail}");
        }

        try
        {
            using var envelope = JsonDocument.Parse(body);
            var text = envelope.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString();
            if (string.IsNullOrWhiteSpace(text)) throw new JsonException();
            var cleanJson = CleanJsonText(text);
            using var result = JsonDocument.Parse(cleanJson);
            return result.RootElement.Clone();
        }
        catch (JsonException)
        {
            throw new AiProviderException("Gemini returned invalid JSON.");
        }
    }

    private async Task<JsonElement> TryGroqAsync(
        string prompt,
        InlineImage? image,
        string reason,
        CancellationToken cancellationToken)
    {
        var key = _configuration["Groq:ApiKey"] ??
            Environment.GetEnvironmentVariable("GROQ_API_KEY");
        if (string.IsNullOrWhiteSpace(key))
        {
            _logger.LogWarning(
                "Gemini failed and Groq fallback is not configured. Reason: {Reason}",
                reason);
            throw new AiProviderException(
                $"Gemini failed ({reason}); Groq fallback is not configured.");
        }

        var model = _configuration["Groq:Model"] ??
            Environment.GetEnvironmentVariable("GROQ_MODEL") ??
            "meta-llama/llama-4-scout-17b-16e-instruct";
        var endpoint = _configuration["Groq:Endpoint"] ??
            Environment.GetEnvironmentVariable("GROQ_ENDPOINT") ??
            "https://api.groq.com/openai/v1/chat/completions";
        var userContent = new List<object> { new { type = "text", text = prompt } };
        if (image is not null)
        {
            userContent.Add(new
            {
                type = "image_url",
                image_url = new
                {
                    url = $"data:{image.MimeType};base64,{Convert.ToBase64String(image.Bytes)}"
                }
            });
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint);
        request.Headers.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", key);
        request.Content = new StringContent(JsonSerializer.Serialize(new
        {
            model,
            temperature = 0.1,
            response_format = new { type = "json_object" },
            messages = new[] { new { role = "user", content = userContent } }
        }), Encoding.UTF8, "application/json");
        HttpResponseMessage response;
        try
        {
            response = await _http.SendAsync(request, cancellationToken);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new AiProviderException("Groq fallback request timed out.");
        }
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            if (response.StatusCode is HttpStatusCode.ServiceUnavailable or HttpStatusCode.BadGateway or HttpStatusCode.GatewayTimeout)
                throw new AiUnavailableException("Groq fallback is temporarily unavailable.");
            if (response.StatusCode == HttpStatusCode.TooManyRequests)
                throw new AiRateLimitException("Groq fallback rate limit reached.");
            throw new AiProviderException(
                $"Groq fallback failed with HTTP {(int)response.StatusCode}: {ExtractProviderError(body)}");
        }

        try
        {
            using var envelope = JsonDocument.Parse(body);
            var text = envelope.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();
            if (string.IsNullOrWhiteSpace(text)) throw new JsonException();
            var cleanJson = CleanJsonText(text);
            using var result = JsonDocument.Parse(cleanJson);
            _logger.LogWarning("Groq fallback used after Gemini failure. Reason: {Reason}", reason);
            return result.RootElement.Clone();
        }
        catch (JsonException)
        {
            throw new AiProviderException("Groq returned invalid JSON.");
        }
    }

    public static string CleanJsonText(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return text;
        var trimmed = text.Trim();
        if (trimmed.StartsWith("```json", StringComparison.OrdinalIgnoreCase))
        {
            trimmed = trimmed["```json".Length..];
        }
        else if (trimmed.StartsWith("```"))
        {
            trimmed = trimmed["```".Length..];
        }
        if (trimmed.EndsWith("```"))
        {
            trimmed = trimmed[..^"```".Length];
        }
        trimmed = trimmed.Trim();

        var firstBrace = trimmed.IndexOf('{');
        var firstBracket = trimmed.IndexOf('[');
        var start = (firstBrace >= 0, firstBracket >= 0) switch
        {
            (true, true) => Math.Min(firstBrace, firstBracket),
            (true, false) => firstBrace,
            (false, true) => firstBracket,
            _ => 0
        };
        var lastBrace = trimmed.LastIndexOf('}');
        var lastBracket = trimmed.LastIndexOf(']');
        var end = Math.Max(lastBrace, lastBracket);
        if (start >= 0 && end > start)
        {
            return trimmed[start..(end + 1)];
        }
        return trimmed;
    }

    private static string ExtractProviderError(string body)
    {
        try
        {
            using var error = JsonDocument.Parse(body);
            return error.RootElement.TryGetProperty("error", out var node)
                ? node.TryGetProperty("message", out var message)
                    ? message.GetString() ?? "The provider returned an error."
                    : node.ToString()
                : "The provider returned an error.";
        }
        catch (JsonException)
        {
            return "The provider returned an invalid error response.";
        }
    }

    private static string BuildRecommendationPrompt(RecommendationRequest request)
    {
        var targetAge = !string.IsNullOrWhiteSpace(request.TargetAgeGroup)
            ? request.TargetAgeGroup
            : !string.IsNullOrWhiteSpace(request.Profile?.AgeGroup)
                ? request.Profile.AgeGroup
                : "unspecified";

        var verifiedPrinciplesRaw = VerifiedBook.Json;

        return $$"""
        Return JSON only with this shape:
        {"ageGroup":"{{targetAge}}","profileAnalysis":{"summary":"","considerations":[],"missingData":[]},"recommendations":[{"mealName":"","catalogId":"","ingredients":[],"reason":"","principles":[],"alternatives":[],"confidence":"low|medium|high"}],"missingData":[]}
        Write all explanations in natural Vietnamese. First analyze the supplied age, weight, height,
        allergies, dislikes and dietary pattern. Describe how these constrain food selection;
        do not diagnose or prescribe from BMI, weight or height. Report missing health context.
        Meal type "day" means suggest options across breakfast, lunch, dinner and snack.
        Recommend only foods from the supplied catalog that are strictly suitable for target age group: '{{targetAge}}'.
        Exclude foods conflicting with user allergies or disliked foods.
        Do not invent calories, portions, diagnoses, medical claims, or book citations.
        Weight and height are context only. For minors, never recommend fasting, calorie restriction, or weight loss.
        Use only supplied verifiedPrinciples. If it is empty, state that verified book data is unavailable.
        Target age group: {{targetAge}}
        Profile: {{JsonSerializer.Serialize(new
        {
            request.Profile?.Age,
            request.Profile?.WeightKg,
            request.Profile?.HeightCm,
            AgeGroup = targetAge,
            request.Profile?.Allergies,
            request.Profile?.DislikedFoods,
            request.Profile?.DietaryPattern
        })}}
        Meal type: {{request.MealType}}
        Catalog: {{JsonSerializer.Serialize(request.Catalog)}}
        Verified principles: {{verifiedPrinciplesRaw}}
        """;
    }

    private static string BuildEvaluationPrompt(EvaluationRequest request)
    {
        var confirmedFoodsJson = request.ConfirmedFoods is { Count: > 0 }
            ? JsonSerializer.Serialize(request.ConfirmedFoods)
            : "[]";

        return $$"""
        Return valid JSON only with this shape:
        {"recognizedFoods":[{"name":"","catalogId":"","confidence":0.0,"evidence":""}],"visibleIngredients":[],"unknownInformation":[],"overallSummary":"","principleAnalyses":[{"principleId":"","principleName":"","sourceType":"BOOK_VERIFIED","sourceChapter":"","sourcePage":"","status":"MATCH|PARTIAL|NOT_MATCH|INSUFFICIENT_DATA","assessment":"","reason":"","explanation":"","improvementPoints":[],"suggestions":[],"reference":""}],"improvementPoints":[],"suggestions":[],"references":[],"confidence":0.0}
        Do not return any scores, points, percentages of diet quality, fitScore or maxScore.
        The catalog is a lookup dictionary, NEVER evidence that a food is present.
        For a photo, recognizedFoods must list only separately visible dishes. Keep composite dish names intact.
        If no food is recognizable, return recognizedFoods: [] and explain the uncertainty. Never fill it from the catalog.
        In manual mode, evaluate all and only confirmedFoods; do not add, omit or rename any dish.
        Use the exact principleId from the server's verified list. Explain each relevant criterion without scoring.
        Adult dietary patterns are not pediatric prescriptions. For users under 18 do not mark adult restrictions
        as requirements. Do not prescribe fasting, protein restriction, calorie targets or weight loss.
        A single meal cannot establish habitual frequency, daily protein quantity or hidden oil/sugar content.
        Analyze only visible evidence or confirmed foods. Never infer hidden ingredients, calories, portions, disease, or diagnosis.
        Return natural Vietnamese text. Never output raw JSON keys (such as sourceChapter, sourcePage, principleId, assessment, status, reason) inside natural text sentences.
        Map a food to catalogId only when the catalog supports that identification.
        Do not guess ingredients that are not visible; put them in unknownInformation or insufficientData.
        Check allergies before suggestions. For minors, never suggest strict calorie limits or weight loss.
        Use only the supplied verified principles. If none are supplied, set principleAnalyses to [],
        references to [], and clearly state that verified source data from the book is unavailable.
        Never invent book content, quotations, chapters, pages, or references.
        Meal type: {{request.MealType}}
        User-supplied health profile: {{request.Profile}}
        User notes: {{request.Notes}}
        Verified principles (curated from local longo.pdf, printed pages and PDF pages are distinct): {{VerifiedBook.Json}}
        Catalog: {{JsonSerializer.Serialize(request.Catalog)}}
        Confirmed foods to evaluate: {{confirmedFoodsJson}}
        """;
    }

    private sealed record InlineImage(string MimeType, byte[] Bytes);
}

public sealed class AiConfigurationException(string message) : Exception(message);
public sealed class AiRateLimitException(string message) : Exception(message);
public sealed class AiProviderException(string message) : Exception(message);
public sealed class AiUnavailableException(string message) : Exception(message);
