namespace Inventory.Application.Pricing.ProductPrices.Queries
{
    public sealed record ProductPriceResponse(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string ProductSku,
        Guid PriceListId,
        string PriceListName,
        decimal Price,
        string Currency,
        DateTime CreatedAt,
        DateTime? UpdatedAt);
}
