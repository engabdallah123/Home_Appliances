using Inventory.Domain.Catalog.Products.Entities;
using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Queries.GetProductSerials
{
    public sealed record GetProductSerialsQuery(
        Guid ProductId,
        ProductSerialStatus? Status = null) : IQuery<IReadOnlyList<ProductSerialResponse>>;
}
