using Dapper;
using Identity.Domain.Users;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Identity.Application.Users.Queries.GetUserById
{
    internal sealed class GetUserByIdQueryHandler : IQueryHandler<GetUserByIdQuery, UserResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetUserByIdQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<UserResponse>> Handle(GetUserByIdQuery request, CancellationToken cancellationToken)
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
                WHERE u.Id = @Id
                """;

            var user = await connection.QuerySingleOrDefaultAsync<UserResponse>(sql, new { request.Id });

            if (user is null)
                return Result<UserResponse>.Failure(UserErrors.NotFound(request.Id));

            return Result<UserResponse>.Success(user);
        }
    }
}
