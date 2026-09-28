using POS.Shared.Application.Messaging;

namespace Returns.Application.PurchaseReturns.Queries.GetPurchaseReturns
{
    public sealed record GetPurchaseReturnsQuery(
        Guid? SupplierId = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<PurchaseReturnResponse>>;
}
