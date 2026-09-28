namespace Inventory.Domain.Stock.StockBalances
{
    public interface IStockBalanceRepository
    {
        Task<StockBalance?> GetByProductAndWarehouseAsync(Guid productId, Guid warehouseId, CancellationToken cancellationToken = default);

        Task<IReadOnlyList<StockBalance>> GetByWarehouseAsync(Guid warehouseId, CancellationToken cancellationToken = default);

        Task<IReadOnlyList<StockBalance>> GetByProductAsync(Guid productId, CancellationToken cancellationToken = default);

        Task<IReadOnlyList<StockBalance>> GetLowStockAsync(int threshold, CancellationToken cancellationToken = default);

        Task<bool> ExistsAsync(Guid productId, Guid warehouseId, CancellationToken cancellationToken = default);

        Task AddAsync(StockBalance stockBalance, CancellationToken cancellationToken = default);
    }
}
