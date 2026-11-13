using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace LongEva.Api;

public static class CatalogPolicy
{
    private static string Normalize(string value) => string.Concat(value.ToLowerInvariant()
        .Normalize(NormalizationForm.FormD).Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark))
        .Replace('đ', 'd');

    public static bool Allows(CatalogFood food, HealthProfileInput? profile)
    {
        if (profile is null || profile.Age is < 2) return false;
        var text = Normalize($"{food.Name} {food.Description} {string.Join(" ", food.Ingredients ?? [])}");
        var excluded = (profile.Allergies ?? []).Concat(profile.DislikedFoods ?? [])
            .Where(term => !string.IsNullOrWhiteSpace(term)).Select(term => Normalize(term.Trim()));
        if (excluded.Any(text.Contains)) return false;
        var diet = Normalize(profile.DietaryPattern ?? "");
        var vegetarian = diet.Contains("chay") || diet.Contains("vegetarian") || diet.Contains("vegan");
        if (vegetarian && new[] { "thit", "ga nuong", "ga luoc", "ga hap", "heo", "lon", "chicken", "beef", "pork", "ca hoi", "ca hap", "ca moi", "ca nuong", "tom", "cua", "muc", "fish", "salmon", "sardine" }
            .Any(term => Regex.IsMatch(text, @"\b" + Regex.Escape(term) + @"\b"))) return false;
        if ((diet.Contains("thuan chay") || diet.Contains("vegan")) &&
            new[] { "trung", "mat ong", "pho mai", "egg", "honey", "cheese" }.Any(text.Contains)) return false;
        return true;
    }
}
