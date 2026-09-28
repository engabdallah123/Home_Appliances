using POS.Shared.Domain;

namespace Audit.Domain.AuditLogs
{
    public static class AuditLogErrors
    {
        public static Error NotFound(Guid id) =>
            new("AuditLog.NotFound", $"سجل المراجعة بالرقم '{id}' غير موجود.");

        public static readonly Error ActionRequired =
            new("AuditLog.ActionRequired", "نوع الإجراء مطلوب.");

        public static readonly Error EntityNameRequired =
            new("AuditLog.EntityNameRequired", "اسم الكيان مطلوب.");
    }
}
