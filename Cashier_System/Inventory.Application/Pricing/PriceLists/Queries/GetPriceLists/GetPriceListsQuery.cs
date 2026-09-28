using POS.Shared.Application.Messaging;

namespace Inventory.Application.Pricing.PriceLists.Queries.GetPriceLists
{
    public sealed record GetPriceListsQuery(bool? OnlyActive = true) : IQuery<IReadOnlyList<PriceListResponse>>;
}
