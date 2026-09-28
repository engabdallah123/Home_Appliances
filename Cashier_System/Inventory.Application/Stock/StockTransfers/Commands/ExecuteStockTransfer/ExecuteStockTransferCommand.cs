using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.StockTransfers.Commands.ExecuteStockTransfer
{
    public sealed record ExecuteStockTransferCommand(
        Guid TransferId,
        string ExecutedBy) : ICommand;
}
