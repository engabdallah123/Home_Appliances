using POS.Shared.Application.Messaging;

namespace Shifts.Application.Shifts.Commands.OpenShift
{
    public sealed record OpenShiftCommand(
        Guid CashierId,
        decimal OpeningCash,
        string? Notes) : ICommand<Guid>;
}
