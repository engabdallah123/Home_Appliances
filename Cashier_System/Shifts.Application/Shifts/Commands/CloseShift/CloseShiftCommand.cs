using POS.Shared.Application.Messaging;

namespace Shifts.Application.Shifts.Commands.CloseShift
{
    public sealed record CloseShiftCommand(
        Guid ShiftId,
        decimal ActualClosingCash,
        string? ClosingNotes) : ICommand;
}
