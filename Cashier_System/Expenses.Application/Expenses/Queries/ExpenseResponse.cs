namespace Expenses.Application.Expenses.Queries
{
    public sealed record ExpenseResponse(
        Guid Id,
        string Title,
        string? Description,
        decimal Amount,
        DateTime ExpenseDate,
        Guid CreatedByUserId,
        string? CreatedByName,
        string? Notes,
        DateTime CreatedAt)
    {
        public string Category => Description ?? string.Empty;
    }
}
