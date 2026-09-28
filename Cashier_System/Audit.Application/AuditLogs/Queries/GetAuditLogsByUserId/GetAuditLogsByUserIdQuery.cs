using POS.Shared.Application.Messaging;

namespace Audit.Application.AuditLogs.Queries.GetAuditLogsByUserId
{
    public sealed record GetAuditLogsByUserIdQuery(
        Guid UserId,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<AuditLogResponse>>;
}
