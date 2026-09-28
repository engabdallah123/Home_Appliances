namespace Inventory.Application.Stock.StockBalances.Queries
{
    public sealed record StockBalanceResponse(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string ProductSku,
        Guid WarehouseId,
        string WarehouseName,
        int QuantityOnHand,
        DateTime LastUpdated);
}
