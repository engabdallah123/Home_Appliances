using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Units.Commands.DeleteUnit
{
    public sealed record DeleteUnitCommand(Guid Id) : ICommand;
}
