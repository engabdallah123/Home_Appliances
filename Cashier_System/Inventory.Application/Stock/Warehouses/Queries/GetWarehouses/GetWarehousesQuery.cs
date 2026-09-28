using POS.Shared.Application.Messaging;

namespace Inventory.Application.Stock.Warehouses.Queries.GetWarehouses
{
    public sealed record GetWarehousesQuery(bool? OnlyActive = true) : IQuery<IReadOnlyList<WarehouseResponse>>;
}
