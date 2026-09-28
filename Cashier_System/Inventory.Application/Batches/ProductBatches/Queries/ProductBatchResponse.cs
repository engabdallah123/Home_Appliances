namespace Inventory.Application.Batches.ProductBatches.Queries
{
    public sealed record ProductBatchResponse(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string ProductSku,
        Guid WarehouseId,
        string WarehouseName,
        string BatchNumber,
        DateTime? ExpiryDate,
        int Quantity,
        bool IsExpired,
        bool IsExpiringSoon,
        DateTime CreatedAt);
}
