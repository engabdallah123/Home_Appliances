using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.StockBalances.Queries.GetStockBalance
{
    public sealed record GetStockBalanceQuery(
        Guid? ProductId = null,
        Guid? WarehouseId = null) : IQuery<IReadOnlyList<StockBalanceResponse>>;
}
