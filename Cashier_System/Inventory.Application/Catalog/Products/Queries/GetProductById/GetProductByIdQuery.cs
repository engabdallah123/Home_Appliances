using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Queries.GetProductById
{
    public sealed record GetProductByIdQuery(Guid Id) : IQuery<ProductResponse>;
}
