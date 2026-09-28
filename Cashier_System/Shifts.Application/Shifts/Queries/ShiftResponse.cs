namespace Shifts.Application.Shifts.Queries
{
    public sealed record ShiftResponse(
        Guid Id,
        Guid CashierId,
        string? CashierName,
        DateTime OpenedAt,
        DateTime? ClosedAt,
        decimal OpeningCash,
        decimal ClosingCash,
        decimal SystemCash,
        decimal CashDifference,
        string Status,
        decimal TotalSales,
        decimal TotalCash,
        decimal TotalCard,
        decimal TotalWallet,
        decimal TotalCredit,
        decimal TotalDiscount,
        decimal TotalTax,
        int TotalInvoices,
        int TotalReturns,
        string? Notes,
        string? ClosingNotes);
}
