using POS.Shared.Application.Messaging;

namespace Identity.Application.Auth.Commands.Login
{
    public sealed record LoginCommand(
        string UserName,
        string Password) : ICommand<AuthResponse>;
}
