using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Commands.DeactivateProduct
{
    public sealed record DeactivateProductCommand(Guid Id) : ICommand;
}
