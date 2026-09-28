using Audit.Domain;
using Audit.Domain.AuditLogs.Entities;
using Audit.Infrastructre.Database;
using POS.Shared.Domain;
using POS.Shared.Infrastructure.Database;

namespace Audit.Infrastructre
{
    public class AuditUnitOfWork : IAuditUnitOfWork
    {
        private readonly AuditDbContext _dbContext;

        public IBaseRepository<AuditLog> AuditLogRepository { get; private set; }

        public AuditUnitOfWork(AuditDbContext dbContext)
        {
            _dbContext = dbContext;
            AuditLogRepository = new BaseRepository<AuditLog>(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
