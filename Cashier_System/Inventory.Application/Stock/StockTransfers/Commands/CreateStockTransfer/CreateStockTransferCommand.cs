using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.StockTransfers.Commands.CreateStockTransfer
{
    public sealed record TransferItemDto(Guid ProductId, int Quantity);

    public sealed record CreateStockTransferCommand(
        string TransferNumber,
        Guid SourceWarehouseId,
        Guid DestinationWarehouseId,
        string CreatedBy,
        string? Notes,
        List<TransferItemDto> Items) : ICommand<Guid>;
}
