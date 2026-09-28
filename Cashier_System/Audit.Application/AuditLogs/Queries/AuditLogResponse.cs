namespace Audit.Application.AuditLogs.Queries
{
    public sealed record AuditLogResponse(
        Guid Id,
        Guid? UserId,
        string Action,
        string EntityName,
        Guid? EntityId,
        string? OldValues,
        string? NewValues,
        string? IpAddress,
        DateTime CreatedAt);
}
