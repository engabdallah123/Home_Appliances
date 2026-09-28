using POS.Shared.Application.Messaging;

namespace Identity.Application.Auth.Commands.RefreshToken
{
    public sealed record RefreshTokenCommand(
        string AccessToken,
        string RefreshToken) : ICommand<AuthResponse>;
}
