using POS.Shared.Domain.Abstractions;

namespace POS.Shared.Domain.Events.Sales
{
    public sealed record SaleCancelledIntegrationEvent(
        Guid SaleId,
        Guid ShiftId,
        decimal TotalAmount) : IDomainEvent;
}
