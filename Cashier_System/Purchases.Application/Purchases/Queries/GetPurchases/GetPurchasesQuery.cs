using POS.Shared.Application.Messaging;

namespace Purchases.Application.Purchases.Queries.GetPurchases
{
    public sealed record GetPurchasesQuery(
        Guid? SupplierId = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<PurchaseResponse>>;
}
