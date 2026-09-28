using POS.Shared.Domain.Abstractions;

namespace POS.Shared.Domain.Events.Returns
{
    public sealed record PurchaseReturnCompletedIntegrationEvent(
        Guid PurchaseReturnId,
        Guid OriginalPurchaseId,
        decimal TotalAmount) : IDomainEvent;
}
