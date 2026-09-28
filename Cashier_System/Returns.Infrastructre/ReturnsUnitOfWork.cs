using POS.Shared.Domain;
using POS.Shared.Infrastructure.Database;
using Returns.Domain;
using Returns.Domain.Returns.Entities;
using Returns.Infrastructre.Database;

namespace Returns.Infrastructre
{
    public class ReturnsUnitOfWork : IReturnsUnitOfWork
    {
        private readonly ReturnsDbContext _dbContext;

        public IBaseRepository<SalesReturn> SalesReturnRepository { get; private set; }
        public IBaseRepository<SalesReturnItem> SalesReturnItemRepository { get; private set; }
        public IBaseRepository<PurchaseReturn> PurchaseReturnRepository { get; private set; }
        public IBaseRepository<PurchaseReturnItem> PurchaseReturnItemRepository { get; private set; }

        public ReturnsUnitOfWork(ReturnsDbContext dbContext)
        {
            _dbContext = dbContext;
            SalesReturnRepository = new BaseRepository<SalesReturn>(_dbContext);
            SalesReturnItemRepository = new BaseRepository<SalesReturnItem>(_dbContext);
            PurchaseReturnRepository = new BaseRepository<PurchaseReturn>(_dbContext);
            PurchaseReturnItemRepository = new BaseRepository<PurchaseReturnItem>(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
