using POS.Shared.Domain.Abstractions;

namespace Inventory.Domain.Stock.StockTransfers.Events
{
    public sealed record StockTransferExecutedDomainEvent(
        Guid TransferId,
        Guid SourceWarehouseId,
        Guid DestinationWarehouseId) : IDomainEvent;
}
