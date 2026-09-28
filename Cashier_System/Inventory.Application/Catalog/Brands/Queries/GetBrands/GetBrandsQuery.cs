using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Brands.Queries.GetBrands
{
    public sealed record GetBrandsQuery(bool? OnlyActive = true) : IQuery<IReadOnlyList<BrandResponse>>;
}
