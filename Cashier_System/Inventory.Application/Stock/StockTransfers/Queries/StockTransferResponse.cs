using Inventory.Domain.Stock.StockTransfers;

namespace Inventory.Application.Stock.StockTransfers.Queries
{
    public sealed record StockTransferResponse(
        Guid Id,
        string TransferNumber,
        Guid SourceWarehouseId,
        string SourceWarehouseName,
        Guid DestinationWarehouseId,
        string DestinationWarehouseName,
        TransferStatus Status,
        string StatusName,
        string? Notes,
        string CreatedBy,
        DateTime CreatedAt,
        DateTime? ExecutedAt);
}
