using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.Warehouses.Commands.CreateWarehouse
{
    public sealed record CreateWarehouseCommand(
        string Name,
        string Code,
        string? Address = null) : ICommand<Guid>;
}
