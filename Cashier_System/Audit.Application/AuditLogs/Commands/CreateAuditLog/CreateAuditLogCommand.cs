using POS.Shared.Application.Messaging;

namespace Audit.Application.AuditLogs.Commands.CreateAuditLog
{
    public sealed record CreateAuditLogCommand(
        Guid? UserId,
        string Action,
        string EntityName,
        Guid? EntityId,
        string? OldValues,
        string? NewValues,
        string? IpAddress) : ICommand<Guid>;
}
