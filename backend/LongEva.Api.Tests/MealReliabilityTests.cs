using System.Net;
using System.Text;
using System.Text.Json;
using LongEva.Api;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace LongEva.Api.Tests;

public class MealReliabilityTests
{
    [Fact]
    public void EvaluationUsesVerifiedPagesAndOmitsScoresAndInventedCriteria()
    {
        var input = JsonSerializer.Deserialize<JsonElement>("""
        {"score":99,"principleAnalyses":[
          {"principleId":"book_complex_carbohydrates","sourcePage":999,"fitScore":100,"status":"MATCH","reason":"Có đậu"},
          {"principleId":"invented","sourcePage":7,"status":"MATCH"}
        ],"recognizedFoods":[{"name":"Sai"}]}
        """);
        var result = GeminiService.NormalizeEvaluation(input, [new CatalogFood("tofu", "Đậu phụ")]);
        Assert.False(result.TryGetProperty("score", out _));
        var criteria = result.GetProperty("principleAnalyses").EnumerateArray().ToArray();
        Assert.Equal(5, criteria.Length);
        Assert.DoesNotContain(criteria, item => item.GetProperty("principleId").GetString() == "invented");
        var carbs = criteria.Single(item => item.GetProperty("principleId").GetString() == "book_complex_carbohydrates");
        Assert.Equal(79, carbs.GetProperty("sourcePage").GetInt32());
        Assert.Equal(11, carbs.GetProperty("sourcePdfPage").GetInt32());
        Assert.False(carbs.TryGetProperty("fitScore", out _));
        Assert.Equal("Đậu phụ", result.GetProperty("recognizedFoods")[0].GetProperty("name").GetString());
    }

    [Fact]
    public void CatalogPolicyExcludesDeclaredAllergensAndVegetarianConflicts()
    {
        var profile = new HealthProfileInput(Age: 25, Allergies: ["chuối"], DietaryPattern: "ăn chay");
        Assert.False(CatalogPolicy.Allows(new CatalogFood("a", "Yến mạch chuối"), profile));
        Assert.False(CatalogPolicy.Allows(new CatalogFood("b", "Cá hồi"), profile));
        Assert.True(CatalogPolicy.Allows(new CatalogFood("c", "Đậu phụ sốt cà chua"), profile));
    }

    [Fact]
    public async Task PhotoPromptNeverUsesTheCatalogAsConfirmedFoodsOrClientBookClaims()
    {
        var handler = new ProviderHandler();
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> {
            ["GEMINI_API_KEY"] = "test-only"
        }).Build();
        var service = new GeminiService(new HttpClient(handler), configuration, NullLogger<GeminiService>.Instance);
        var result = await service.EvaluateAsync(new EvaluationRequest(
            "lunch", "{}", "", "UNTRUSTED_BOOK_CLAIM",
            [new CatalogFood("catalog_food", "Món trong danh mục")],
            MimeType: "image/jpeg", ImageBytes: [0xff, 0xd8, 0xff]), CancellationToken.None);
        using var request = JsonDocument.Parse(handler.RequestBody!);
        var prompt = request.RootElement.GetProperty("contents")[0].GetProperty("parts")[0].GetProperty("text").GetString()!;
        Assert.Contains("Confirmed foods to evaluate: []", prompt);
        Assert.DoesNotContain("UNTRUSTED_BOOK_CLAIM", prompt);
        Assert.Contains("sourcePdfPage", prompt);
        Assert.Empty(result.GetProperty("recognizedFoods").EnumerateArray());
    }

    private sealed class ProviderHandler : HttpMessageHandler
    {
        public string? RequestBody;
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            RequestBody = await request.Content!.ReadAsStringAsync(cancellationToken);
            return new HttpResponseMessage(HttpStatusCode.OK) {
                Content = new StringContent(JsonSerializer.Serialize(new {
                    candidates = new[] { new { content = new { parts = new[] { new {
                        text = "{\"recognizedFoods\":[],\"principleAnalyses\":[]}"
                    } } } } }
                }), Encoding.UTF8, "application/json")
            };
        }
    }
}
