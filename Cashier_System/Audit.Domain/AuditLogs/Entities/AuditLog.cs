using POS.Shared.Domain;

namespace Audit.Domain.AuditLogs.Entities
{
    public sealed class AuditLog : Entity
    {
        public Guid? UserId { get; private set; }
        public string Action { get; private set; } = default!;
        public string EntityName { get; private set; } = default!;
        public Guid? EntityId { get; private set; }
        public string? OldValues { get; private set; }
        public string? NewValues { get; private set; }
        public string? IpAddress { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private AuditLog() { } // EF Core

        private AuditLog(Guid id, Guid? userId, string action, string entityName,
            Guid? entityId, string? oldValues, string? newValues, string? ipAddress)
            : base(id)
        {
            UserId = userId;
            Action = action;
            EntityName = entityName;
            EntityId = entityId;
            OldValues = oldValues;
            NewValues = newValues;
            IpAddress = ipAddress;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<AuditLog> Create(
            Guid? userId, string action, string entityName,
            Guid? entityId = null, string? oldValues = null,
            string? newValues = null, string? ipAddress = null)
        {
            if (string.IsNullOrWhiteSpace(action))
                return Result<AuditLog>.Failure(AuditLogErrors.ActionRequired);

            if (string.IsNullOrWhiteSpace(entityName))
                return Result<AuditLog>.Failure(AuditLogErrors.EntityNameRequired);

            var log = new AuditLog(
                Guid.NewGuid(), userId, action.Trim(), entityName.Trim(),
                entityId, oldValues, newValues, ipAddress?.Trim());

            return Result<AuditLog>.Success(log);
        }
    }
}
