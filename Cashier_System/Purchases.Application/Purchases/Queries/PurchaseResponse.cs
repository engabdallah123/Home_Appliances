namespace Purchases.Application.Purchases.Queries
{
    public sealed record PurchaseItemResponse(
        Guid Id,
        Guid ProductId,
        string? ProductName,
        decimal Quantity,
        decimal UnitCost,
        decimal Discount,
        decimal Tax,
        decimal Total,
        DateTime? ExpiryDate,
        string? BatchNumber);

    public sealed class PurchaseResponse
    {
        public Guid Id { get; set; }
        public string InvoiceNumber { get; set; } = string.Empty;
        public string? InternalNumber { get; set; }
        public Guid SupplierId { get; set; }
        public string? SupplierName { get; set; }
        public DateTime PurchaseDate { get; set; }
        public DateTime? ReceivedDate { get; set; }
        public decimal SubTotal { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal TaxAmount { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public string PaymentMethod { get; set; } = "Cash";
        public string Status { get; set; } = "Received";
        public string? Notes { get; set; }
        public Guid CreatedByUserId { get; set; }
        public IReadOnlyList<PurchaseItemResponse> Items { get; set; } = Array.Empty<PurchaseItemResponse>();
    }
}
