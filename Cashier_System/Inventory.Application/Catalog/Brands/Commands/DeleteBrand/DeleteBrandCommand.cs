using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Brands.Commands.DeleteBrand
{
    public sealed record DeleteBrandCommand(Guid Id) : ICommand;
}
