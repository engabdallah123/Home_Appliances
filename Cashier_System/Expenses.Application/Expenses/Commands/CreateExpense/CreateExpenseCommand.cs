using POS.Shared.Application.Messaging;

namespace Expenses.Application.Expenses.Commands.CreateExpense
{
    public sealed record CreateExpenseCommand(
        string Title,
        decimal Amount,
        Guid CreatedByUserId,
        string? Description = null,
        DateTime? ExpenseDate = null,
        string? Notes = null) : ICommand<Guid>;
}
