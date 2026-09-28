using POS.Shared.Domain;
using POS.Shared.Infrastructure.Database;
using Sales.Domain;
using Sales.Domain.Customers.Entities;
using Sales.Domain.Installments.Entities;
using Sales.Domain.Promotions.Entities;
using Sales.Domain.Sales.Entities;
using Sales.Infrastructre.Database;

namespace Sales.Infrastructre
{
    public class SalesUnitOfWork : ISalesUnitOfWork
    {
        private readonly SalesDbContext _dbContext;

        public IBaseRepository<Customer> CustomerRepository { get; private set; }
        public IBaseRepository<Sale> SaleRepository { get; private set; }
        public IBaseRepository<SaleItem> SaleItemRepository { get; private set; }
        public IBaseRepository<SalePayment> SalePaymentRepository { get; private set; }
        public IBaseRepository<InstallmentContract> InstallmentContractRepository { get; private set; }
        public IBaseRepository<InstallmentSchedule> InstallmentScheduleRepository { get; private set; }
        public IBaseRepository<Offer> OfferRepository { get; private set; }
        public IBaseRepository<OfferItem> OfferItemRepository { get; private set; }

        public SalesUnitOfWork(SalesDbContext dbContext)
        {
            _dbContext = dbContext;
            CustomerRepository = new BaseRepository<Customer>(_dbContext);
            SaleRepository = new BaseRepository<Sale>(_dbContext);
            SaleItemRepository = new BaseRepository<SaleItem>(_dbContext);
            SalePaymentRepository = new BaseRepository<SalePayment>(_dbContext);
            InstallmentContractRepository = new BaseRepository<InstallmentContract>(_dbContext);
            InstallmentScheduleRepository = new BaseRepository<InstallmentSchedule>(_dbContext);
            OfferRepository = new BaseRepository<Offer>(_dbContext);
            OfferItemRepository = new BaseRepository<OfferItem>(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
