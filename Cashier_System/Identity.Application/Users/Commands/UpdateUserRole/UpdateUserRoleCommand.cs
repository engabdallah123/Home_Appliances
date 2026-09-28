using POS.Shared.Application.Messaging;

namespace Identity.Application.Users.Commands.UpdateUserRole
{
    public sealed record UpdateUserRoleCommand(string UserId, string Role) : ICommand;
}
