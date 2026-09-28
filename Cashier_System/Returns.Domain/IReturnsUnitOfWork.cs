using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;
using Returns.Domain.Returns.Entities;

namespace Returns.Domain
{
    public interface IReturnsUnitOfWork : IUnitOfWork
    {
        IBaseRepository<SalesReturn> SalesReturnRepository { get; }
        IBaseRepository<SalesReturnItem> SalesReturnItemRepository { get; }
        IBaseRepository<PurchaseReturn> PurchaseReturnRepository { get; }
        IBaseRepository<PurchaseReturnItem> PurchaseReturnItemRepository { get; }
    }
}
