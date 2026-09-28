using POS.Shared.Application.Messaging;

namespace Identity.Application.Users.Commands.DeactivateUser
{
    public sealed record DeactivateUserCommand(string Id) : ICommand;
}
