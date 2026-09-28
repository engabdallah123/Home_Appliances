using POS.Shared.Application.Messaging;

namespace Inventory.Application.Batches.ProductBatches.Commands.CreateProductBatch
{
    public sealed record CreateProductBatchCommand(
        Guid ProductId,
        Guid WarehouseId,
        string BatchNumber,
        DateTime? ExpiryDate,
        int Quantity) : ICommand<Guid>;
}
