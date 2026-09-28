using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Categories.Commands.ActivateCategory
{
    public sealed record ActivateCategoryCommand(Guid Id) : ICommand;
}
