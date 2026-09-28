using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;
using Sales.Domain.Customers.Entities;
using Sales.Domain.Installments.Entities;
using Sales.Domain.Promotions.Entities;
using Sales.Domain.Sales.Entities;

namespace Sales.Domain
{
    public interface ISalesUnitOfWork : IUnitOfWork
    {
        IBaseRepository<Customer> CustomerRepository { get; }
        IBaseRepository<Sale> SaleRepository { get; }
        IBaseRepository<SaleItem> SaleItemRepository { get; }
        IBaseRepository<SalePayment> SalePaymentRepository { get; }
        IBaseRepository<InstallmentContract> InstallmentContractRepository { get; }
        IBaseRepository<InstallmentSchedule> InstallmentScheduleRepository { get; }
        IBaseRepository<Offer> OfferRepository { get; }
        IBaseRepository<OfferItem> OfferItemRepository { get; }
    }
}
