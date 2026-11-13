using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace LongEva.Api;

public interface IMealImageStorage
{
    Task<MealImageResponse> UploadAsync(byte[] image, string contentType, CancellationToken cancellationToken);
}

/// <summary>A publicly accessible Cloudinary image URL and its asset identifier.</summary>
public sealed record MealImageResponse(string Url, string PublicId);

public sealed class CloudinaryImageService(HttpClient client, IConfiguration configuration) : IMealImageStorage
{
    public async Task<MealImageResponse> UploadAsync(byte[] image, string contentType, CancellationToken cancellationToken)
    {
        var cloud = configuration["Cloudinary:CloudName"];
        var key = configuration["Cloudinary:ApiKey"];
        var secret = configuration["Cloudinary:ApiSecret"];
        if (string.IsNullOrWhiteSpace(cloud) || string.IsNullOrWhiteSpace(key) || string.IsNullOrWhiteSpace(secret))
            throw new InvalidOperationException("Cloudinary is not configured.");
        if (!System.Text.RegularExpressions.Regex.IsMatch(cloud, "^[a-zA-Z0-9_-]+$"))
            throw new InvalidOperationException("Cloudinary cloud name is invalid.");

        using var request = new HttpRequestMessage(HttpMethod.Post, $"https://api.cloudinary.com/v1_1/{cloud}/image/upload");
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", Convert.ToBase64String(Encoding.UTF8.GetBytes($"{key}:{secret}")));
        using var form = new MultipartFormDataContent();
        using var file = new ByteArrayContent(image);
        file.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        form.Add(file, "file", "meal-image");
        form.Add(new StringContent("longeva/meals"), "folder");
        request.Content = form;
        using var response = await client.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode) throw new HttpRequestException("Cloudinary upload failed.");
        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var json = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
        if (!json.RootElement.TryGetProperty("secure_url", out var url) ||
            !json.RootElement.TryGetProperty("public_id", out var id) ||
            !Uri.TryCreate(url.GetString(), UriKind.Absolute, out var parsed) || parsed.Scheme != Uri.UriSchemeHttps ||
            string.IsNullOrWhiteSpace(id.GetString()))
            throw new HttpRequestException("Cloudinary returned an invalid response.");
        return new MealImageResponse(parsed.ToString(), id.GetString()!);
    }
}
