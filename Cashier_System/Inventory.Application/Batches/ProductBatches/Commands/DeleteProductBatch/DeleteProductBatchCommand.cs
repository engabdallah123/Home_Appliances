using POS.Shared.Application.Messaging;

namespace Inventory.Application.Batches.ProductBatches.Commands.DeleteProductBatch
{
    public sealed record DeleteProductBatchCommand(Guid Id) : ICommand;
}
