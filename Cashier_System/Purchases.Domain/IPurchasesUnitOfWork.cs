using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;
using Purchases.Domain.Purchases.Entities;
using Purchases.Domain.Suppliers.Entities;

namespace Purchases.Domain
{
    public interface IPurchasesUnitOfWork : IUnitOfWork
    {
        IBaseRepository<Supplier> SupplierRepository { get; }
        IBaseRepository<Purchase> PurchaseRepository { get; }
        IBaseRepository<PurchaseItem> PurchaseItemRepository { get; }
    }
}
