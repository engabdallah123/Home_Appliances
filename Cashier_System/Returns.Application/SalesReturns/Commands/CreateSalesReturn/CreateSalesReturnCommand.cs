using POS.Shared.Application.Messaging;

namespace Returns.Application.SalesReturns.Commands.CreateSalesReturn
{
    public sealed record CreateSalesReturnItemRequest(
        Guid ProductId,
        Guid OriginalSaleItemId,
        decimal Quantity,
        decimal UnitPrice,
        decimal Tax = 0,
        string? Reason = null);

    public sealed record CreateSalesReturnCommand(
        Guid OriginalSaleId,
        Guid CashierId,
        Guid ShiftId,
        List<CreateSalesReturnItemRequest> Items,
        Guid? CustomerId = null,
        int RefundMethod = 1,
        string? Reason = null,
        string? Notes = null) : ICommand<Guid>;
}
