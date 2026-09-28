using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.StockMovements.Queries.GetStockMovements
{
    public sealed record StockMovementResponse(
        Guid Id,
        Guid ProductId,
        string? ProductName,
        string? Barcode,
        decimal Quantity,
        string Type,
        string? Reference,
        string? Notes,
        DateTime MovementDate,
        Guid UserId,
        string? UserName);

    public sealed record GetStockMovementsQuery(
        Guid? ProductId = null,
        DateTime? FromDate = null,
        DateTime? ToDate = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<StockMovementResponse>>;
}
