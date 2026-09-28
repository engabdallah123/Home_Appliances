using POS.Shared.Domain.Abstractions;

namespace POS.Shared.Domain.Events.Returns
{
    public sealed record SalesReturnCompletedIntegrationEvent(
        Guid SalesReturnId,
        Guid OriginalSaleId,
        Guid ShiftId,
        decimal TotalAmount,
        string RefundMethod) : IDomainEvent;
}
