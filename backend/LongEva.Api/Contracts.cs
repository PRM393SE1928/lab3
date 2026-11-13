using System.Text.Json;

namespace LongEva.Api;

public sealed record RecommendationRequest(
    HealthProfileInput? Profile,
    string MealType,
    IReadOnlyList<CatalogFood> Catalog,
    JsonElement? VerifiedPrinciples = null,
    string? TargetAgeGroup = null);

public sealed record HealthProfileInput(
    int? Age = null,
    string? AgeGroup = null,
    double? WeightKg = null,
    int? HeightCm = null,
    IReadOnlyList<string>? Allergies = null,
    IReadOnlyList<string>? DislikedFoods = null,
    string? DietaryPattern = null);

public sealed record CatalogFood(string Id, string Name, string? Category = null, string? Description = null, IReadOnlyList<string>? Ingredients = null, IReadOnlyList<string>? AgeGroups = null);

public sealed record ManualEvaluationRequest(
    string MealType,
    IReadOnlyList<CatalogFood> ConfirmedFoods,
    string? Profile = null,
    string? Notes = null,
    string? Principles = null);

public sealed record EvaluationRequest(
    string MealType,
    string Profile,
    string Notes,
    string Principles,
    IReadOnlyList<CatalogFood> Catalog,
    IReadOnlyList<CatalogFood>? ConfirmedFoods = null,
    string? MimeType = null,
    byte[]? ImageBytes = null);
