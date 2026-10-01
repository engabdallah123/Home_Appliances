namespace Sales.Application.Sales.Queries
{
    public sealed record SaleItemResponse(
        Guid Id,
        Guid ProductId,
        string? ProductName,
        string? Barcode,
        decimal Quantity,
        decimal UnitPrice,
        decimal Discount,
        decimal Tax,
        decimal Total,
        string? UnitName = null,
        string? PriceType = null,
        string? PackagingInfo = null,
        string? SerialNumber = null,
        string? BrandName = null,
        string? ModelNumber = null,
        int WarrantyPeriodMonths = 0,
        string? MaintenanceAgent = null);

    public sealed class SaleResponse
    {
        public Guid Id { get; set; }
        public string InvoiceNumber { get; set; } = string.Empty;
        public DateTime SaleDate { get; set; }
        public Guid CashierId { get; set; }
        public string? CashierName { get; set; }
        public Guid? CustomerId { get; set; }
        public string? CustomerName { get; set; }
        public Guid ShiftId { get; set; }
        public decimal SubTotal { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal TaxAmount { get; set; }
        public decimal DeliveryFee { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal ChangeAmount { get; set; }
        public string PaymentMethod { get; set; } = "Cash";
        public string Status { get; set; } = "Completed";
        public string? Notes { get; set; }

        // Delivery
        public bool IsDelivery { get; set; }
        public string? RecipientName { get; set; }
        public string? RecipientPhone { get; set; }
        public string? DeliveryAddress { get; set; }
        public string? DeliveryFloor { get; set; }
        public string? DriverName { get; set; }
        public int DeliveryStatus { get; set; }

        // Reservation
        public bool IsReserved { get; set; }
        public DateTime? TargetDeliveryDate { get; set; }
        public int ReservationStatus { get; set; }

        // Installment
        public bool IsInstallment { get; set; }
        public Guid? InstallmentContractId { get; set; }

        public IReadOnlyList<SaleItemResponse> Items { get; set; } = Array.Empty<SaleItemResponse>();
    }

    public sealed record ReceiptResponse(
        string StoreName,
        string? Address,
        string? Phone,
        string InvoiceNumber,
        DateTime SaleDate,
        string CashierName,
        string? CustomerName,
        IReadOnlyList<SaleItemResponse> Items,
        decimal SubTotal,
        decimal DiscountAmount,
        decimal TaxAmount,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal ChangeAmount,
        string PaymentMethod,
        string Currency,
        string? InvoiceFooterMessage,
        string? LogoUrl = null,
        byte[]? LogoBytes = null,
        string? HeaderImageUrl = null,
        byte[]? HeaderImageBytes = null,
        string? FooterImageUrl = null,
        byte[]? FooterImageBytes = null,
        string? OrderType = null,
        int OrderNumber = 1,
        // Appliance specifics
        bool IsDelivery = false,
        string? RecipientName = null,
        string? RecipientPhone = null,
        string? DeliveryAddress = null,
        decimal DeliveryFee = 0,
        bool IsReserved = false,
        DateTime? TargetDeliveryDate = null,
        bool IsInstallment = false,
        string? InstallmentSummary = null,
        string? CustomerPhone = null,
        string? CustomerAddress = null,
        string? DriverName = null,
        string? SaleType = null);
}
