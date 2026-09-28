using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Categories.Commands.DeleteCategory
{
    public sealed record DeleteCategoryCommand(Guid Id) : ICommand;
}
