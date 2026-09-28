using POS.Shared.Application.Messaging;

namespace Audit.Application.AuditLogs.Queries.GetAuditLogById
{
    public sealed record GetAuditLogByIdQuery(Guid Id) : IQuery<AuditLogResponse>;
}
