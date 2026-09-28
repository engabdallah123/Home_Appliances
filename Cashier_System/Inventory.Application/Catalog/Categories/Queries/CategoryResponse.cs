namespace Inventory.Application.Catalog.Categories.Queries
{
    public sealed record CategoryResponse(
        Guid Id,
        string NameAr,
        string NameEn,
        Guid? ParentCategoryId,
        bool IsActive,
        DateTime CreatedAt);
}
