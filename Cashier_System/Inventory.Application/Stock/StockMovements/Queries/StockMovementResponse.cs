using Inventory.Domain.Stock.StockMovements;

namespace Inventory.Application.Stock.StockMovements.Queries
{
    public sealed record StockMovementResponse(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string ProductSku,
        Guid WarehouseId,
        string WarehouseName,
        StockMovementType Type,
        string TypeName,
        int Quantity,
        int BeforeQuantity,
        int AfterQuantity,
        string ReferenceType,
        Guid? ReferenceId,
        DateTime CreatedAt,
        string CreatedBy);
}
