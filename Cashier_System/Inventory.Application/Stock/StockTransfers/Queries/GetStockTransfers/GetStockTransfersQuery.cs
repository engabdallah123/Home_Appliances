using Inventory.Domain.Stock.StockTransfers;
using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.StockTransfers.Queries.GetStockTransfers
{
    public sealed record GetStockTransfersQuery(
        Guid? SourceWarehouseId = null,
        Guid? DestinationWarehouseId = null,
        TransferStatus? Status = null) : IQuery<IReadOnlyList<StockTransferResponse>>;
}
