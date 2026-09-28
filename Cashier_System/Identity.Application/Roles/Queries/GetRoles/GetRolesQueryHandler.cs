using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Identity.Application.Roles.Queries.GetRoles
{
    internal sealed class GetRolesQueryHandler : IQueryHandler<GetRolesQuery, IReadOnlyList<RoleResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetRolesQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<RoleResponse>>> Handle(GetRolesQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT Id, Name
                FROM [Identity].[AspNetRoles]
                ORDER BY Name
                """;

            var roles = await connection.QueryAsync<RoleResponse>(sql);
            return Result<IReadOnlyList<RoleResponse>>.Success(roles.ToList());
        }
    }
}
