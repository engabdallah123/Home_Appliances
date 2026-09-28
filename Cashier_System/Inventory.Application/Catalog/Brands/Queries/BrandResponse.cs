namespace Inventory.Application.Catalog.Brands.Queries
{
    public sealed record BrandResponse(
        Guid Id,
        string Name,
        bool IsActive,
        DateTime CreatedAt,
        string? NameAr = null,
        string? NameEn = null);
}
