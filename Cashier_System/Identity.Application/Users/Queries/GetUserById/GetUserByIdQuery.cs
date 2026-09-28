using POS.Shared.Application.Messaging;

namespace Identity.Application.Users.Queries.GetUserById
{
    public sealed record GetUserByIdQuery(string Id) : IQuery<UserResponse>;
}
