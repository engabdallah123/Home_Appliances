namespace Returns.Application.PurchaseReturns.Queries.GetPurchaseReturns
{
    public sealed record PurchaseReturnResponse(
        Guid Id,
        string ReturnNumber,
        Guid OriginalPurchaseId,
        Guid SupplierId,
        string? SupplierName,
        DateTime ReturnDate,
        decimal SubTotal,
        decimal TaxAmount,
        decimal TotalAmount,
        string? Reason,
        string? Notes,
        string Status);
}
