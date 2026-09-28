using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Units.Commands.CreateUnit
{
    public sealed record CreateUnitCommand(
        string NameAr,
        string NameEn,
        string Symbol) : ICommand<Guid>;
}
