using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Audit.Application.AuditLogs.Queries.GetAuditLogs
{
    internal sealed class GetAuditLogsQueryHandler : IQueryHandler<GetAuditLogsQuery, IReadOnlyList<AuditLogResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetAuditLogsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<AuditLogResponse>>> Handle(GetAuditLogsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    Id, UserId, Action, EntityName, EntityId,
                    OldValues, NewValues, IpAddress, CreatedAt
                FROM [Audit].[AuditLogs]
                WHERE 1 = 1
                """;

            if (!string.IsNullOrWhiteSpace(request.EntityName))
                sql += " AND EntityName = @EntityName";

            if (!string.IsNullOrWhiteSpace(request.Action))
                sql += " AND Action = @Action";

            sql += " ORDER BY CreatedAt DESC OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var offset = (request.Page - 1) * request.PageSize;

            var logs = await connection.QueryAsync<AuditLogResponse>(sql, new
            {
                request.EntityName,
                request.Action,
                Offset = offset,
                request.PageSize
            });

            return Result<IReadOnlyList<AuditLogResponse>>.Success(logs.ToList());
        }
    }
}
