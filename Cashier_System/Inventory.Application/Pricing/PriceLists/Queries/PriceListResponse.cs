namespace Inventory.Application.Pricing.PriceLists.Queries
{
    public sealed record PriceListResponse(
        Guid Id,
        string Name,
        string? Description,
        bool IsDefault,
        bool IsActive,
        DateTime CreatedAt);
}
