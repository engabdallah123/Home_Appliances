using POS.Shared.Application.Messaging;

namespace Identity.Application.Users.Queries.GetUsers
{
    public sealed record GetUsersQuery() : IQuery<IReadOnlyList<UserResponse>>;
}
