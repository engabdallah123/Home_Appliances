using POS.Shared.Domain.Abstractions;

namespace POS.Shared.Domain.Events.Shifts
{
    public sealed record ShiftOpenedIntegrationEvent(
        Guid ShiftId,
        Guid CashierId,
        decimal OpeningCash) : IDomainEvent;
}
