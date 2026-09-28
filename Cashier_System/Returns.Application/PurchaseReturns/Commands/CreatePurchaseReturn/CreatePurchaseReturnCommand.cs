using POS.Shared.Application.Messaging;

namespace Returns.Application.PurchaseReturns.Commands.CreatePurchaseReturn
{
    public sealed record CreatePurchaseReturnItemRequest(
        Guid ProductId,
        decimal Quantity,
        decimal UnitCost,
        decimal Tax = 0);

    public sealed record CreatePurchaseReturnCommand(
        Guid OriginalPurchaseId,
        Guid SupplierId,
        Guid CreatedByUserId,
        List<CreatePurchaseReturnItemRequest> Items,
        string? Reason = null,
        string? Notes = null) : ICommand<Guid>;
}
