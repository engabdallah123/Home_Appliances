using POS.Shared.Domain.Abstractions;

namespace POS.Shared.Domain.Events.Shifts
{
    public sealed record ShiftClosedIntegrationEvent(
        Guid ShiftId,
        Guid CashierId,
        decimal SystemCash,
        decimal CashDifference) : IDomainEvent;
}
