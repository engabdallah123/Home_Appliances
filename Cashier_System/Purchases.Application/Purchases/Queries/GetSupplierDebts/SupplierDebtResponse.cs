namespace Purchases.Application.Purchases.Queries.GetSupplierDebts
{
    public sealed record SupplierDebtResponse(
        Guid PurchaseId,
        string InvoiceNumber,
        DateTime PurchaseDate,
        Guid SupplierId,
        string? SupplierName,
        string? SupplierPhone,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal RemainingAmount,
        string Status);
}
