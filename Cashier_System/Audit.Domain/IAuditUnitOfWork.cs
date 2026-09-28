using Audit.Domain.AuditLogs.Entities;
using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;

namespace Audit.Domain
{
    public interface IAuditUnitOfWork : IUnitOfWork
    {
        IBaseRepository<AuditLog> AuditLogRepository { get; }
    }
}
