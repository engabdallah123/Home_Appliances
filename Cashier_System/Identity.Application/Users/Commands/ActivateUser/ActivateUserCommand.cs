using POS.Shared.Application.Messaging;

namespace Identity.Application.Users.Commands.ActivateUser
{
    public sealed record ActivateUserCommand(string Id) : ICommand;
}
