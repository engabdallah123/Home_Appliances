namespace Sales.Application.Sales.Queries.GetCustomerDebts
{
    public sealed record CustomerDebtResponse(
        Guid SaleId,
        string InvoiceNumber,
        DateTime SaleDate,
        Guid? CustomerId,
        string? CustomerName,
        string? CustomerPhone,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal RemainingAmount,
        string PaymentMethod,
        string Status);
}
