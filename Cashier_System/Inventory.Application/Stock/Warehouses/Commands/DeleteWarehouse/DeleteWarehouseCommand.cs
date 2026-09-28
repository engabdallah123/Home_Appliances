using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.Warehouses.Commands.DeleteWarehouse
{
    public sealed record DeleteWarehouseCommand(Guid Id) : ICommand;
}
