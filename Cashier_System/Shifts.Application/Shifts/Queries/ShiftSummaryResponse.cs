namespace Shifts.Application.Shifts.Queries
{
    public sealed record ShiftSummaryResponse(
        Guid ShiftId,
        Guid CashierId,
        string? CashierName,
        DateTime OpenedAt,
        DateTime? ClosedAt,
        string Status,
        decimal OpeningCash,
        decimal TotalSales,
        decimal TotalCash,
        decimal TotalCard,
        decimal TotalWallet,
        decimal TotalCredit,
        decimal TotalDiscount,
        decimal TotalTax,
        int TotalInvoices,
        int TotalReturns,
        decimal ExpectedCashInDrawer,
        decimal ActualClosingCash,
        decimal CashDifference);
}
