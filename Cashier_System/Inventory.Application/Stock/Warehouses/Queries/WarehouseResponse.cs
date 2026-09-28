namespace Inventory.Application.Stock.Warehouses.Queries
{
    public sealed record WarehouseResponse(
        Guid Id,
        string Name,
        string Code,
        string? Address,
        bool IsActive);
}
