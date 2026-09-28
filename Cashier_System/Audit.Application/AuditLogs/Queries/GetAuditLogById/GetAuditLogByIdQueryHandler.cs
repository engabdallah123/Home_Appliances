using Audit.Domain.AuditLogs;
using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Audit.Application.AuditLogs.Queries.GetAuditLogById
{
    internal sealed class GetAuditLogByIdQueryHandler : IQueryHandler<GetAuditLogByIdQuery, AuditLogResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetAuditLogByIdQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<AuditLogResponse>> Handle(GetAuditLogByIdQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT 
                    Id, UserId, Action, EntityName, EntityId,
                    OldValues, NewValues, IpAddress, CreatedAt
                FROM [Audit].[AuditLogs]
                WHERE Id = @Id
                """;

            var log = await connection.QuerySingleOrDefaultAsync<AuditLogResponse>(sql, new { request.Id });

            if (log is null)
                return Result<AuditLogResponse>.Failure(AuditLogErrors.NotFound(request.Id));

            return Result<AuditLogResponse>.Success(log);
        }
    }
}
