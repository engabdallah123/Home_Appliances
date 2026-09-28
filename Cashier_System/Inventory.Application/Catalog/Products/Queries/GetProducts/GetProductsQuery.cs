using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Queries.GetProducts
{
    public sealed record GetProductsQuery(
        Guid? CategoryId = null,
        string? SearchTerm = null,
        bool? IsActive = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<ProductResponse>>;
}
