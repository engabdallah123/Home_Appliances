using POS.Shared.Application.Messaging;

namespace Expenses.Application.Expenses.Queries.GetExpenses
{
    public sealed record GetExpensesQuery(
        DateTime? FromDate = null,
        DateTime? ToDate = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<ExpenseResponse>>;
}
