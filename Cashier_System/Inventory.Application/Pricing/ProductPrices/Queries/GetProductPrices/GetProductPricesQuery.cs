using POS.Shared.Application.Messaging;

namespace Inventory.Application.Pricing.ProductPrices.Queries.GetProductPrices
{
    public sealed record GetProductPricesQuery(
        Guid? ProductId = null,
        Guid? PriceListId = null) : IQuery<IReadOnlyList<ProductPriceResponse>>;
}
