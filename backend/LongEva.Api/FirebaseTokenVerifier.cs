using FirebaseAdmin;
using FirebaseAdmin.Auth;

namespace LongEva.Api;

public sealed class FirebaseTokenVerifier
{
    private readonly IConfiguration _configuration;
    private readonly Lazy<Task<FirebaseApp?>> _app;

    public FirebaseTokenVerifier(IConfiguration configuration)
    {
        _configuration = configuration;
        _app = new(() => CreateAppAsync());
    }

    public async Task<FirebaseToken?> VerifyAsync(HttpRequest request, CancellationToken cancellationToken)
    {
        var header = request.Headers.Authorization.ToString();
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)) return null;
        var app = await _app.Value;
        if (app is null) return null;
        try
        {
            return await FirebaseAuth.GetAuth(app).VerifyIdTokenAsync(header["Bearer ".Length..].Trim());
        }
        catch (FirebaseAuthException)
        {
            return null;
        }
    }

    private Task<FirebaseApp?> CreateAppAsync()
    {
        var credentialsPath = _configuration["Firebase:ServiceAccountPath"] ??
            Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");
        var projectId = _configuration["Firebase:ProjectId"] ??
            Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID");
        if (string.IsNullOrWhiteSpace(credentialsPath) &&
            string.IsNullOrWhiteSpace(projectId))
            return Task.FromResult<FirebaseApp?>(null);
        try
        {
            return Task.FromResult<FirebaseApp?>(FirebaseApp.DefaultInstance ??
                FirebaseApp.Create(new AppOptions
                {
                    Credential = string.IsNullOrWhiteSpace(credentialsPath)
                        ? Google.Apis.Auth.OAuth2.GoogleCredential.GetApplicationDefaultAsync()
                            .GetAwaiter()
                            .GetResult()
                        : Google.Apis.Auth.OAuth2.GoogleCredential.FromFile(credentialsPath),
                    ProjectId = projectId
                }));
        }
        catch (Exception ex) when (ex is InvalidOperationException or ArgumentException)
        {
            return Task.FromResult<FirebaseApp?>(null);
        }
    }
}
