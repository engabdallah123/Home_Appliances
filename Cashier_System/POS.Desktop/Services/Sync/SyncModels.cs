namespace POS.Desktop.Services.Sync
{
    public class SyncStatusResult
    {
        public bool Success { get; set; }
        public int SyncedPurchasesCount { get; set; }
        public int SyncedSalesCount { get; set; }
        public int SyncedCatalogCount { get; set; }
        public int SyncedDebtsCount { get; set; }
        public string? Message { get; set; }
        public string? Error { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.Now;
    }

    public record CloudPurchaseSyncItemDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? Barcode,
        decimal Quantity,
        decimal UnitCost,
        decimal Discount,
        decimal Tax,
        decimal Total,
        DateTime? ExpiryDate,
        string? BatchNumber,
        string? Unit);

    public record CloudPurchaseSyncDto(
        Guid Id,
        string InvoiceNumber,
        string? InternalNumber,
        Guid SupplierId,
        string? SupplierName,
        DateTime PurchaseDate,
        decimal SubTotal,
        decimal DiscountAmount,
        decimal TaxAmount,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal RemainingAmount,
        int PaymentMethod,
        string? Notes,
        string? CreatedByName,
        string SyncStatus,
        DateTime? SyncedAt,
        string? SyncError,
        int SyncAttempts,
        DateTime CreatedAt,
        List<CloudPurchaseSyncItemDto> Items);

    public record AcknowledgeCloudSyncRequest(
        Guid PurchaseId,
        string? LocalReference = null);

    public record FailCloudSyncRequest(
        Guid PurchaseId,
        string ErrorMessage);

    public record PushCloudCatalogRequest(
        List<CatalogSupplierSyncItem>? Suppliers,
        List<CatalogProductSyncItem>? Products,
        List<CatalogCategorySyncItem>? Categories = null);

    public record CatalogCategorySyncItem(
        Guid Id,
        string NameAr,
        string? NameEn = null);

    public record CatalogSupplierSyncItem(
        Guid Id,
        string Name,
        string? Phone,
        string? Address,
        decimal Balance,
        string? Email = null,
        string? ContactPerson = null);

    public record PushStoreSettingsRequest(
        string StoreName,
        string? Address,
        string? Phone,
        decimal TaxRate,
        bool IsTaxIncluded,
        string Currency,
        string? InvoiceFooterMessage,
        bool AllowNegativeStock,
        string? LogoUrl);

    public record CatalogProductSyncItem(
        Guid Id,
        string Barcode,
        string NameAr,
        string? NameEn,
        string BaseUnit,
        string? ParentUnit,
        int ConversionFactor,
        decimal PurchasePrice,
        decimal SellingPrice,
        decimal WholesalePrice,
        decimal StockQuantity,
        Guid? CategoryId,
        string? CategoryName,
        bool IsWeighable,
        int ShelfLifeDays,
        int ExpiryAlertDays,
        decimal ReorderLevel,
        bool TrackExpiry,
        Guid? BrandId = null,
        string? BrandName = null,
        string? ModelNumber = null,
        string? Color = null,
        int WarrantyPeriodMonths = 12,
        string? MaintenanceAgent = null,
        bool HasSerialNumber = false);

    public record StockUpdateItem(
        Guid ProductId,
        decimal NewStockQuantity);

    public record PushStockRequest(
        List<StockUpdateItem> Items);

    public record SupplierBalanceUpdateItem(
        Guid SupplierId,
        decimal NewBalance);

    public record PushSupplierBalancesRequest(
        List<SupplierBalanceUpdateItem> Items);

    public record DebtItemSyncDto(
        Guid Id,
        string Type,
        Guid ReferenceId,
        string InvoiceNumber,
        string EntityName,
        string? Phone,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal RemainingAmount,
        DateTime Date);

    public record PushDebtsRequest(
        List<DebtItemSyncDto> Debts);

    public record PushDashboardSnapshotRequest(
        decimal TodaySales,
        decimal TodayProfit,
        decimal TodayPurchases,
        decimal TodayExpenses,
        decimal MonthSales,
        decimal MonthProfit,
        decimal MonthPurchases,
        decimal MonthExpenses,
        decimal CustomerDebtsTotal,
        decimal SupplierDebtsTotal,
        int LowStockCount,
        int ExpiryAlertsCount,
        string? MonthlySalesJson,
        decimal TodayWasteLoss = 0,
        decimal MonthWasteLoss = 0,
        decimal TotalWasteLoss = 0,
        decimal CustomerCreditDebtsTotal = 0,
        decimal InstallmentDebtsTotal = 0,
        int CustomerCreditDebtsCount = 0,
        int InstallmentContractsCount = 0);

    public record PendingDebtPaymentDto(
        Guid Id,
        string DebtType,
        Guid ReferenceId,
        decimal Amount,
        string? Notes,
        DateTime CreatedAt);

    public record PendingCloudProductDto(
        Guid Id,
        string Barcode,
        string NameAr,
        string? NameEn,
        string BaseUnit,
        string? ParentUnit,
        int ConversionFactor,
        decimal PurchasePrice,
        decimal SellingPrice,
        decimal WholesalePrice,
        decimal StockQuantity,
        Guid? CategoryId,
        string? CategoryName,
        bool IsWeighable,
        int ShelfLifeDays,
        int ExpiryAlertDays,
        decimal ReorderLevel,
        bool TrackExpiry,
        bool IsActive = true,
        string? SyncStatus = null,
        Guid? BrandId = null,
        string? BrandName = null,
        string? ModelNumber = null,
        string? Color = null,
        int WarrantyPeriodMonths = 12,
        string? MaintenanceAgent = null,
        bool HasSerialNumber = false);

    public record PendingCloudSupplierDto(
        Guid Id,
        string Name,
        string Phone,
        string? Email,
        string? Address,
        string? ContactPerson);

    // Expenses Sync DTOs
    public record CloudExpenseSyncDto(
        Guid Id,
        decimal Amount,
        string Category,
        string? Description,
        DateTime Date,
        string? Notes);

    public record PushExpensesRequest(
        List<CloudExpenseSyncDto> Expenses);

    // Expiry Notifications Sync DTOs
    public record CloudExpiryNotificationItemDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? Barcode,
        Guid? BatchId,
        string? BatchNumber,
        decimal RemainingQuantity,
        string Unit,
        decimal UnitCost,
        DateTime? ExpiryDate,
        int DaysRemaining,
        bool IsExpired,
        string Message,
        string Status);

    public record PushExpiryNotificationsRequest(
        List<CloudExpiryNotificationItemDto> Notifications);

    public record PendingNotificationActionDto(
        Guid NotificationId,
        Guid ProductId,
        Guid? BatchId,
        string ActionType,
        decimal Quantity,
        string? Reason,
        DateTime? NewExpiryDate,
        string? NewBatchNumber,
        string? Notes,
        DateTime ActionTakenAt);

    // Shift Summary DTOs
    public record PushClosedShiftRequest(
        Guid ShiftId,
        string CashierName,
        DateTime OpenedAt,
        DateTime ClosedAt,
        decimal OpeningCash,
        decimal ActualClosingCash,
        decimal SystemCash,
        decimal CashDifference,
        decimal TotalSales,
        decimal TotalCash,
        decimal TotalCard,
        decimal TotalWallet,
        decimal TotalCredit,
        int TotalInvoices,
        int TotalReturns,
        string? ClosingNotes);

    public record PendingCloudCategoryDto(
        Guid Id,
        string NameAr,
        string? NameEn,
        bool IsActive,
        DateTime CreatedAt);

    public record CloudSyncStatusDto(
        bool HasPending,
        bool HasPendingPurchases,
        bool HasPendingSuppliers,
        bool HasPendingDebts,
        bool HasPendingNotificationActions,
        bool HasPendingCategories,
        DateTime ServerTime,
        bool HasPendingSales = false,
        bool HasPendingProducts = false,
        bool HasPendingBrands = false);

    public record CloudSaleItemSyncDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? Barcode,
        string? ModelNumber,
        string? BrandName,
        string? SerialNumber,
        int WarrantyPeriodMonths,
        decimal Quantity,
        decimal UnitPrice,
        decimal Discount,
        decimal Tax,
        decimal Total);

    public record CloudSaleSyncDto(
        Guid Id,
        string InvoiceNumber,
        Guid? CustomerId,
        string? CustomerName,
        string? CustomerPhone,
        DateTime SaleDate,
        decimal SubTotal,
        decimal DiscountAmount,
        decimal TaxAmount,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal RemainingAmount,
        string PaymentMethod,
        string? Notes,
        bool IsDelivery,
        string? RecipientName,
        string? RecipientPhone,
        string? DeliveryAddress,
        string? DeliveryFloor,
        decimal DeliveryFee,
        bool IsInstallment,
        string? GuarantorName,
        string? GuarantorPhone,
        decimal InterestPercentage,
        int NumberOfMonths,
        bool IsReserved,
        DateTime? TargetDeliveryDate,
        List<CloudSaleItemSyncDto> Items,
        int ReservationStatus = 0,
        string? CreatedByName = null);

    public record PushSalesRequest(List<CloudSaleSyncDto> Sales);

    public record ReturnItemSyncDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? Barcode,
        decimal Quantity,
        decimal UnitPrice,
        decimal Tax,
        decimal Total,
        string? Reason);

    public record PushReturnSyncItem(
        Guid Id,
        string ReturnNumber,
        string Type,
        string? OriginalInvoiceNumber,
        string? PartyName,
        string? PartyPhone,
        DateTime ReturnDate,
        decimal TotalAmount,
        string RefundMethod,
        string? Reason,
        string? Notes,
        string? ItemsJson,
        int ItemsCount);

    public record PushReturnsRequest(List<PushReturnSyncItem> Returns);

    // Offers Push DTOs
    public record PushOfferItemDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? ProductBarcode,
        decimal Quantity,
        decimal OriginalUnitPrice);

    public record PushOfferDto(
        Guid Id,
        string Title,
        string? Description,
        int Type,
        string OfferType,
        decimal? DiscountPercentage,
        decimal? FixedDiscountAmount,
        decimal? BundlePrice,
        DateTime StartDate,
        DateTime EndDate,
        bool IsActive,
        Guid? TargetProductId,
        string? TargetProductName,
        Guid? TargetCategoryId,
        string? TargetCategoryName,
        Guid? TargetBrandId,
        string? TargetBrandName,
        List<PushOfferItemDto>? Items);

    public record PushOffersRequest(List<PushOfferDto> Offers);

    // Brands Sync DTOs
    public record PushBrandDto(
        Guid Id,
        string Name,
        string? NameAr,
        string? NameEn,
        string? Description,
        string? OriginCountry,
        string? AgentContactNumber,
        bool IsActive);

    public record PushBrandsRequest(List<PushBrandDto> Brands);

    public record PendingCloudBrandDto(
        Guid Id,
        string? Name,
        string? NameAr,
        string? NameEn,
        string? Description,
        string? OriginCountry = null,
        string? AgentContactNumber = null,
        bool IsActive = true,
        DateTime? CreatedAt = null);

    // ==========================================
    // Monitoring, Stages & Control Models
    // ==========================================
    public enum SyncStageStatus
    {
        Pending,
        InProgress,
        Completed,
        Skipped,
        Failed
    }

    public class SyncStageItem
    {
        public string Id { get; set; } = string.Empty;
        public string NameAr { get; set; } = string.Empty;
        public string DescriptionAr { get; set; } = string.Empty;
        public string Icon { get; set; } = "fa-solid fa-cloud";
        public SyncStageStatus Status { get; set; } = SyncStageStatus.Pending;
        public string? Details { get; set; }
        public DateTime? StartedAt { get; set; }
        public DateTime? FinishedAt { get; set; }
    }

    public class PendingSyncItemView
    {
        public Guid Id { get; set; }
        public string EntityType { get; set; } = string.Empty; // "Purchase", "Sale", "Product", "DebtPayment", "Expense", "Brand"
        public string Title { get; set; } = string.Empty;
        public string Subtitle { get; set; } = string.Empty;
        public string Details { get; set; } = string.Empty;
        public decimal? Amount { get; set; }
        public DateTime Date { get; set; } = DateTime.Now;
        public string Source { get; set; } = "Mobile"; // "Mobile" or "Local"
        public string Status { get; set; } = "Pending";
    }
}
