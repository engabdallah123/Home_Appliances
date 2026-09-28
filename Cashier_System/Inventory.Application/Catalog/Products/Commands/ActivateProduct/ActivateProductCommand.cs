using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Commands.ActivateProduct
{
    public sealed record ActivateProductCommand(Guid Id) : ICommand;
}
