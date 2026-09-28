using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Categories.Queries.GetCategories
{
    public sealed record GetCategoriesQuery(bool? OnlyActive = true) : IQuery<IReadOnlyList<CategoryResponse>>;
}
