namespace Identity.Application.Auth
{
    public sealed record AuthResponse(
        string AccessToken,
        string RefreshToken,
        DateTime Expiration,
        string UserId,
        string FullName,
        string Role);
}
