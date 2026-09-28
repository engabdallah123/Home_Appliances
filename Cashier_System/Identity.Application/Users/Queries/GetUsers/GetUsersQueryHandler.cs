using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Identity.Application.Users.Queries.GetUsers
{
    internal sealed class GetUsersQueryHandler : IQueryHandler<GetUsersQuery, IReadOnlyList<UserResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetUsersQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<UserResponse>>> Handle(GetUsersQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT 
                    u.Id,
                    u.FullName,
                    u.UserName,
                    u.Email,
                    u.Phone,
                    u.IsActive,
                    u.CreatedAt,
                    ISNULL(r.Name, 'Cashier') AS Role
                FROM [Identity].[AspNetUsers] u
                LEFT JOIN [Identity].[AspNetUserRoles] ur ON u.Id = ur.UserId
                LEFT JOIN [Identity].[AspNetRoles] r ON ur.RoleId = r.Id
                ORDER BY u.CreatedAt DESC
                """;

            var users = await connection.QueryAsync<UserResponse>(sql);
            return Result<IReadOnlyList<UserResponse>>.Success(users.ToList());
        }
    }
}
