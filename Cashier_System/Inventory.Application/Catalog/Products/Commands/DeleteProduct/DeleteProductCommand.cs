using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Commands.DeleteProduct
{
    public sealed record DeleteProductCommand(Guid Id) : ICommand;
}
