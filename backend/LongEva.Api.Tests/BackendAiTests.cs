using System.Text;
using System.Text.Json;
using Xunit;
using LongEva.Api;

namespace LongEva.Api.Tests;

public class BackendAiTests
{
    [Fact]
    public void CleanJsonText_PlainJson_ReturnsUnchanged()
    {
        var input = """{"recognizedFoods":[{"name":"Cơm gạo lứt"}]}""";
        var cleaned = GeminiService.CleanJsonText(input);
        Assert.Equal(input, cleaned);
    }

    [Fact]
    public void CleanJsonText_MarkdownCodeFence_StripsFence()
    {
        var input = """
        ```json
        {
          "overallSummary": "Bữa ăn cân đối",
          "principleAnalyses": []
        }
        ```
        """;
        var cleaned = GeminiService.CleanJsonText(input);
        using var doc = JsonDocument.Parse(cleaned);
        Assert.Equal("Bữa ăn cân đối", doc.RootElement.GetProperty("overallSummary").GetString());
    }

    [Fact]
    public void CleanJsonText_WithExplanatoryText_ExtractsJson()
    {
        var input = """
        Dưới đây là kết quả phân tích bữa ăn:
        ```
        {
          "recognizedFoods": [{"name": "Salad"}],
          "confidence": 0.95
        }
        ```
        Hy vọng thông tin này hữu ích.
        """;
        var cleaned = GeminiService.CleanJsonText(input);
        using var doc = JsonDocument.Parse(cleaned);
        Assert.Equal(0.95, doc.RootElement.GetProperty("confidence").GetDouble());
    }

    [Fact]
    public void RecommendationRequest_Deserialization_WithObjectVerifiedPrinciples_SucceedsWithout400()
    {
        // This reproduces the exact JSON sent by Flutter that previously threw 400 Bad Request
        var flutterPayload = """
        {
          "profile": {
            "age": 21,
            "ageGroup": "age18To59",
            "allergies": ["peanut"],
            "dislikedFoods": ["mushroom"],
            "dietaryPattern": "vegetarian"
          },
          "targetAgeGroup": "age18To59",
          "mealType": "breakfast",
          "catalog": [
            {
              "id": "breakfast_oat_banana",
              "name": "Yến mạch chuối",
              "category": "breakfast",
              "description": "Yến mạch nấu chuối"
            }
          ],
          "verifiedPrinciples": [
            {
              "id": "book_plant_based_nuts_fish",
              "name": "Chủ yếu thực vật, có các loại hạt và một phần cá",
              "description": "Mô tả nguyên tắc từ sách",
              "sourceType": "bookVerified",
              "sourceChapter": "Chapter 4",
              "sourcePage": 11,
              "evaluationCriteria": ["Tiêu chí 1", "Tiêu chí 2"],
              "applicableAgeGroups": ["age18To59"]
            }
          ]
        }
        """;

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var request = JsonSerializer.Deserialize<RecommendationRequest>(flutterPayload, options);

        Assert.NotNull(request);
        Assert.NotNull(request.Profile);
        Assert.Equal(21, request.Profile.Age);
        Assert.Equal("age18To59", request.Profile.AgeGroup);
        Assert.Equal("age18To59", request.TargetAgeGroup);
        Assert.Equal("breakfast", request.MealType);
        Assert.Single(request.Catalog);
        Assert.True(request.VerifiedPrinciples.HasValue);
        Assert.Equal(JsonValueKind.Array, request.VerifiedPrinciples.Value.ValueKind);
    }

    [Fact]
    public void ManualEvaluationRequest_Deserialization_Succeeds()
    {
        var json = """
        {
          "mealType": "lunch",
          "confirmedFoods": [
            {"id": "food_1", "name": "Đậu phụ sốt cà chua", "category": "lunch"}
          ],
          "profile": "{}",
          "principles": "[]"
        }
        """;

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var request = JsonSerializer.Deserialize<ManualEvaluationRequest>(json, options);

        Assert.NotNull(request);
        Assert.Equal("lunch", request.MealType);
        Assert.Single(request.ConfirmedFoods);
        Assert.Equal("food_1", request.ConfirmedFoods[0].Id);
    }
}

