using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Categories.Commands.DeactivateCategory
{
    public sealed record DeactivateCategoryCommand(Guid Id) : ICommand;
}
