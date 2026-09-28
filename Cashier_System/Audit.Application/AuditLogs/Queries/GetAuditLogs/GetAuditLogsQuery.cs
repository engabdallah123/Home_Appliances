using POS.Shared.Application.Messaging;

namespace Audit.Application.AuditLogs.Queries.GetAuditLogs
{
    public sealed record GetAuditLogsQuery(
        int Page = 1,
        int PageSize = 50,
        string? EntityName = null,
        string? Action = null) : IQuery<IReadOnlyList<AuditLogResponse>>;
}
