using POS.Shared.Application.Messaging;

namespace Sales.Application.Installments.Commands.PayInstallmentSchedule
{
    public sealed record PayInstallmentScheduleCommand(
        Guid ContractId,
        Guid ScheduleId,
        decimal Amount,
        string PaymentMethod = "Cash",
        Guid? CashierId = null,
        Guid? ShiftId = null,
        string? Notes = null) : ICommand;
}
