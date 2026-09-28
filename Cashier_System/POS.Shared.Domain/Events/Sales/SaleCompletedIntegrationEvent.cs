using POS.Shared.Domain.Abstractions;

namespace POS.Shared.Domain.Events.Sales
{
    public sealed record SaleCompletedIntegrationEvent(
        Guid SaleId,
        Guid ShiftId,
        decimal TotalAmount,
        string PaymentMethod) : IDomainEvent;
}
