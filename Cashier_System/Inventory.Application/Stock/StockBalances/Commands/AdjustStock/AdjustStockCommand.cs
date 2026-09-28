using Inventory.Domain.Stock.StockMovements;
using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.StockBalances.Commands.AdjustStock
{
    public sealed record AdjustStockCommand(
        Guid ProductId,
        Guid WarehouseId,
        int Quantity,
        StockMovementType MovementType,
        string ReferenceType,
        Guid? ReferenceId,
        string PerformedBy) : ICommand;
}
