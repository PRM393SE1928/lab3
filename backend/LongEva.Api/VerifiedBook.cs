using System.Text.Json;

namespace LongEva.Api;

public static class VerifiedBook
{
    private static readonly Lazy<string> Source = new(() =>
        File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "docs", "verified-principles.json")));
    public static string Json => Source.Value;
    public static IReadOnlyList<JsonElement> Principles => JsonSerializer.Deserialize<List<JsonElement>>(Json)!;
}
