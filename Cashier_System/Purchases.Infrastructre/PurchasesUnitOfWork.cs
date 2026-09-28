using POS.Shared.Domain;
using POS.Shared.Infrastructure.Database;
using Purchases.Domain;
using Purchases.Domain.Purchases.Entities;
using Purchases.Domain.Suppliers.Entities;
using Purchases.Infrastructre.Database;

namespace Purchases.Infrastructre
{
    public class PurchasesUnitOfWork : IPurchasesUnitOfWork
    {
        private readonly PurchasesDbContext _dbContext;

        public IBaseRepository<Supplier> SupplierRepository { get; private set; }
        public IBaseRepository<Purchase> PurchaseRepository { get; private set; }
        public IBaseRepository<PurchaseItem> PurchaseItemRepository { get; private set; }

        public PurchasesUnitOfWork(PurchasesDbContext dbContext)
        {
            _dbContext = dbContext;
            SupplierRepository = new BaseRepository<Supplier>(_dbContext);
            PurchaseRepository = new BaseRepository<Purchase>(_dbContext);
            PurchaseItemRepository = new BaseRepository<PurchaseItem>(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
