using POS.Shared.Application.Messaging;

namespace Identity.Application.Roles.Queries.GetRoles
{
    public sealed record GetRolesQuery() : IQuery<IReadOnlyList<RoleResponse>>;
}
