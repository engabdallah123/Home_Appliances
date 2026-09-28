using POS.Shared.Application.Messaging;

namespace Inventory.Application.Batches.ProductBatches.Queries.GetExpiringBatches
{
    public sealed record GetExpiringBatchesQuery(
        int DaysThreshold = 30,
        Guid? WarehouseId = null) : IQuery<IReadOnlyList<ProductBatchResponse>>;
}
