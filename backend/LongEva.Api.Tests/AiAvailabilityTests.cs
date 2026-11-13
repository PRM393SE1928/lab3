using System.Net;
using System.Text.Json;
using LongEva.Api;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace LongEva.Api.Tests;

public class AiAvailabilityTests
{
    [Fact]
    public async Task TemporaryOverloadIsRetriedAndCanRecover()
    {
        var handler = new SequenceHandler(HttpStatusCode.ServiceUnavailable, HttpStatusCode.OK);
        var result = await Service(handler).EvaluateAsync(Request(), CancellationToken.None);
        Assert.Equal(2, handler.Calls);
        Assert.True(result.TryGetProperty("principleAnalyses", out _));
    }

    [Fact]
    public async Task PersistentOverloadPreservesUnavailableWithoutUnconfiguredFallback()
    {
        var handler = new SequenceHandler(HttpStatusCode.ServiceUnavailable);
        await Assert.ThrowsAsync<AiUnavailableException>(() => Service(handler).EvaluateAsync(Request(), CancellationToken.None));
        Assert.Equal(3, handler.Calls);
    }

    [Fact]
    public async Task QuotaIsNotRetriedOrChangedToBadGateway()
    {
        var handler = new SequenceHandler(HttpStatusCode.TooManyRequests);
        await Assert.ThrowsAsync<AiRateLimitException>(() => Service(handler).EvaluateAsync(Request(), CancellationToken.None));
        Assert.Equal(1, handler.Calls);
    }

    [Fact]
    public async Task CallerCancellationDoesNotTriggerRetry()
    {
        var handler = new SequenceHandler(HttpStatusCode.ServiceUnavailable);
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => Service(handler).EvaluateAsync(Request(), cancellation.Token));
        Assert.True(handler.Calls <= 1);
    }

    private static EvaluationRequest Request() => new("lunch", "{}", "", "", [], [new CatalogFood("tofu", "Đậu phụ")]);
    private static GeminiService Service(HttpMessageHandler handler) => new(new HttpClient(handler),
        new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> {
            ["GEMINI_API_KEY"] = "test", ["Groq:ApiKey"] = ""
        }).Build(), NullLogger<GeminiService>.Instance);

    private sealed class SequenceHandler(params HttpStatusCode[] statuses) : HttpMessageHandler
    {
        public int Calls;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var status = statuses[Math.Min(Calls++, statuses.Length - 1)];
            var body = status == HttpStatusCode.OK
                ? JsonSerializer.Serialize(new { candidates = new[] { new { content = new { parts = new[] { new { text = "{\"recognizedFoods\":[],\"principleAnalyses\":[]}" } } } } } })
                : "{\"error\":{\"message\":\"high demand\"}}";
            return Task.FromResult(new HttpResponseMessage(status) { Content = new StringContent(body) });
        }
    }
}
