using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Audit.Application.AuditLogs.Queries.GetAuditLogsByUserId
{
    internal sealed class GetAuditLogsByUserIdQueryHandler : IQueryHandler<GetAuditLogsByUserIdQuery, IReadOnlyList<AuditLogResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetAuditLogsByUserIdQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<AuditLogResponse>>> Handle(GetAuditLogsByUserIdQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT 
                    Id, UserId, Action, EntityName, EntityId,
                    OldValues, NewValues, IpAddress, CreatedAt
                FROM [Audit].[AuditLogs]
                WHERE UserId = @UserId
                ORDER BY CreatedAt DESC
                OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY
                """;

            var offset = (request.Page - 1) * request.PageSize;

            var logs = await connection.QueryAsync<AuditLogResponse>(sql, new
            {
                request.UserId,
                Offset = offset,
                request.PageSize
            });

            return Result<IReadOnlyList<AuditLogResponse>>.Success(logs.ToList());
        }
    }
}
