using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.Warehouses.Commands.UpdateWarehouse
{
    public sealed record UpdateWarehouseCommand(
        Guid Id,
        string Name,
        string Code,
        string? Address) : ICommand;
}
