using POS.Shared.Application.Messaging;

namespace Purchases.Application.Purchases.Queries.GetPurchaseById
{
    public sealed record GetPurchaseByIdQuery(Guid Id) : IQuery<PurchaseDetailResponse>;
}
