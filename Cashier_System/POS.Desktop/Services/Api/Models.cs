namespace POS.Desktop.Services.Api
{
    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;

        public LoginRequest() { }
        public LoginRequest(string username, string password)
        {
            Username = username;
            Password = password;
        }
    }

    public record AuthResponse(string AccessToken, string RefreshToken, DateTime Expiration, string UserId, string FullName, string Role);

    public record ProductDto(
        Guid Id,
        string Barcode,
        string NameAr,
        string NameEn,
        string? Description,
        Guid CategoryId,
        string? CategoryName,
        Guid UnitId,
        string? UnitSymbol,
        Guid? SupplierId,
        string? SupplierName,
        decimal PurchasePrice,
        decimal SellingPrice,
        decimal WholesalePrice,
        decimal QuantityInStock,
        decimal ReorderLevel,
        decimal MaxStockLevel,
        bool IsWeighable,
        bool IsActive,
        bool TrackExpiry,
        decimal TaxRate,
        string? ImageUrl,
        string BaseUnit = "قطعة",
        string? ParentUnit = "كرتونة",
        int ConversionFactor = 1,
        int ShelfLifeDays = 0,
        int ExpiryAlertDays = 3,
        Guid? BrandId = null,
        string? BrandName = null,
        string? ModelNumber = null,
        string? Color = null,
        int WarrantyPeriodMonths = 12,
        string? MaintenanceAgent = null,
        bool HasSerialNumber = false);

    public class ProductImportResultDto
    {
        public int TotalRows { get; set; }
        public int SuccessCount { get; set; }
        public int ErrorCount { get; set; }
        public List<ProductImportErrorDto> Errors { get; set; } = new();
    }

    public class ProductImportErrorDto
    {
        public int RowNumber { get; set; }
        public string Barcode { get; set; } = string.Empty;
        public string ProductName { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
    }

    public record CategoryDto(
        Guid Id,
        string NameAr,
        string NameEn,
        Guid? ParentCategoryId,
        bool IsActive = true,
        DateTime CreatedAt = default);

    public record CreateCategoryRequest(string NameAr, string? NameEn = null, Guid? ParentCategoryId = null, Guid? Id = null);
    public record UpdateCategoryRequest(Guid Id, string NameAr, string? NameEn = null, Guid? ParentCategoryId = null);

    public record UpdateProductCommandModel(
        Guid Id,
        string Barcode,
        string NameAr,
        string NameEn,
        string? Description,
        Guid CategoryId,
        Guid UnitId,
        Guid? SupplierId,
        decimal PurchasePrice,
        decimal SellingPrice,
        decimal WholesalePrice,
        decimal ReorderLevel,
        decimal MaxStockLevel,
        bool IsWeighable,
        bool IsActive,
        bool TrackExpiry,
        decimal TaxRate,
        string? ImageUrl,
        string BaseUnit = "قطعة",
        string? ParentUnit = "كرتونة",
        int ConversionFactor = 1,
        int ShelfLifeDays = 0,
        int ExpiryAlertDays = 3,
        Guid? BrandId = null,
        string? ModelNumber = null,
        string? Color = null,
        int WarrantyPeriodMonths = 12,
        string? MaintenanceAgent = null,
        bool HasSerialNumber = false);

    public class CreateProductFormModel
    {
        public string Barcode { get; set; } = string.Empty;
        public string NameAr { get; set; } = string.Empty;
        public string NameEn { get; set; } = string.Empty;
        public string? Description { get; set; }
        public Guid CategoryId { get; set; }
        public Guid UnitId { get; set; }
        public Guid? SupplierId { get; set; }
        public string BaseUnit { get; set; } = "قطعة";
        public string? ParentUnit { get; set; } = "كرتونة";
        public int ConversionFactor { get; set; } = 1;
        public int ShelfLifeDays { get; set; } = 0;
        public int ExpiryAlertDays { get; set; } = 3;
        public decimal PurchasePrice { get; set; }
        public decimal SellingPrice { get; set; }
        public decimal WholesalePrice { get; set; }
        public decimal ReorderLevel { get; set; } = 5;
        public decimal MaxStockLevel { get; set; } = 100;
        public bool IsWeighable { get; set; }
        public bool IsActive { get; set; } = true;
        public bool TrackExpiry { get; set; }
        public decimal TaxRate { get; set; }
        public Guid? Id { get; set; }
        public decimal InitialStock { get; set; } = 0;

        // Appliance Specific Fields
        public Guid? BrandId { get; set; }
        public string? ModelNumber { get; set; }
        public string? Color { get; set; }
        public int WarrantyPeriodMonths { get; set; } = 12;
        public string? MaintenanceAgent { get; set; }
        public bool HasSerialNumber { get; set; } = false;
    }
    public record UnitDto(Guid Id, string NameAr, string NameEn, string Symbol);
    public record CreateUnitRequest(string NameAr, string NameEn, string Symbol);
    public record SupplierDto(Guid Id, string Name, string Phone, string? Email, string? Address, string? ContactPerson);
    public record CustomerDto(Guid Id, string Name, string Phone, string? Email, string? Address, int LoyaltyPoints, decimal Balance);
    public record CreateCustomerRequest(string Name, string Phone, string? Email = null, string? Address = null);

    public record CreateSaleItemRequest(
        Guid ProductId, 
        decimal Quantity, 
        decimal UnitPrice, 
        decimal Discount = 0, 
        decimal Tax = 0,
        string? SerialNumber = null);

    public record CreateSaleCommand(
        Guid CashierId,
        Guid ShiftId,
        List<CreateSaleItemRequest> Items,
        Guid? CustomerId = null,
        decimal DiscountAmount = 0,
        decimal TaxAmount = 0,
        decimal PaidAmount = 0,
        string PaymentMethod = "Cash",
        string? Notes = null,
        // Delivery
        bool IsDelivery = false,
        string? RecipientName = null,
        string? RecipientPhone = null,
        string? DeliveryAddress = null,
        string? DeliveryFloor = null,
        decimal DeliveryFee = 0,
        string? DriverName = null,
        // Layaway / Reservation
        bool IsReserved = false,
        DateTime? TargetDeliveryDate = null,
        // Installments
        bool IsInstallment = false,
        string? GuarantorName = null,
        string? GuarantorPhone = null,
        string? GuarantorNationalId = null,
        string? GuarantorAddress = null,
        string? GuarantorNotes = null,
        decimal InterestPercentage = 0,
        int NumberOfMonths = 12,
        DateTime? InstallmentStartDate = null,
        string? CustomInvoiceNumber = null,
        bool BypassStockCheck = false);

    public record DepletedBatchDto(
        Guid BatchId,
        Guid ProductId,
        string ProductName,
        string BatchNumber,
        decimal OriginalQuantity,
        string OriginalUnit,
        DateTime PurchaseDate,
        DateTime? ExpiryDate,
        Guid? PurchaseInvoiceId
    );

    public record CreateSaleResult(
        Guid SaleId,
        List<DepletedBatchDto>? DepletedBatches
    );

    public record ReplenishBatchRequest(
        decimal Quantity,
        string? Notes = null
    );

    public record OpenShiftCommand(Guid CashierId, decimal OpeningCash, string? Notes = null);
    public record CloseShiftCommand(Guid ShiftId, decimal ActualClosingCash, string? ClosingNotes = null);
    public record ShiftDto(
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
        decimal TotalSales = 0,
        decimal TotalCash = 0,
        decimal TotalCard = 0,
        decimal TotalWallet = 0,
        decimal TotalCredit = 0,
        decimal TotalDiscount = 0,
        decimal TotalTax = 0,
        int TotalInvoices = 0,
        int TotalReturns = 0,
        string? Notes = null,
        string? ClosingNotes = null);

    public record PeriodMetricsDto(
        decimal TotalSales,
        decimal NetProfit,
        int TotalInvoices,
        decimal TotalPurchases,
        decimal TotalExpenses,
        decimal CashSales = 0,
        decimal CreditSales = 0,
        decimal DebtCollections = 0,
        decimal RealizedRevenue = 0);

    public record PaymentMethodSummaryDto(
        string PaymentMethod,
        decimal TotalAmount,
        int InvoiceCount,
        decimal Percentage);

    public record LowStockProductDto(
        Guid ProductId,
        string ProductName,
        string Barcode,
        decimal QuantityInStock,
        decimal ReorderLevel);

    public record CashierPerformanceDto(
        Guid CashierId,
        string CashierName,
        int TotalShifts,
        int TotalInvoices,
        decimal TotalSalesAmount,
        decimal TotalCashDifference);

    public record CustomerDebtSummaryDto(
        Guid? CustomerId,
        string CustomerName,
        string? CustomerPhone,
        decimal TotalDebtAmount,
        int InvoicesCount,
        DateTime LastSaleDate);

    public record WasteLossesDto(
        decimal TodayLoss,
        decimal WeekLoss,
        decimal MonthLoss,
        decimal TotalLoss);

    public record DashboardDataDto(
        decimal TotalSales,
        int TotalInvoices,
        decimal TotalPurchases,
        decimal TotalExpenses,
        decimal NetProfit,
        decimal TotalSalesReturns,
        decimal TotalPurchaseReturns,
        decimal AverageInvoiceValue,
        decimal ProfitMarginPercentage,
        int LowStockProductsCount,
        PeriodMetricsDto? TodayMetrics,
        PeriodMetricsDto? MonthMetrics,
        PeriodMetricsDto? YearMetrics,
        List<TopProductDto>? TopSellingProducts,
        List<CashierPerformanceDto>? CashierPerformances,
        List<PaymentMethodSummaryDto>? PaymentMethodsSummary,
        List<LowStockProductDto>? LowStockProductsList,
        decimal TotalCustomerDebts = 0,
        int CustomerDebtsCount = 0,
        List<CustomerDebtSummaryDto>? TopCustomerDebts = null,
        WasteLossesDto? WasteLosses = null,
        int ActiveExpiryNotificationsCount = 0,
        decimal CashSalesAmount = 0,
        decimal CreditSalesAmount = 0,
        decimal DebtCollectionsAmount = 0,
        decimal RealizedRevenue = 0,
        decimal TotalCustomerCreditDebts = 0,
        int CustomerCreditDebtsCount = 0,
        decimal TotalInstallmentDebts = 0,
        int InstallmentContractsCount = 0,
        decimal OverdueInstallmentsAmount = 0,
        int OverdueInstallmentsCount = 0)
    {
        public int LowStockCount => LowStockProductsCount;
    }

    public record TopProductDto(
        Guid ProductId,
        string? ProductName,
        string? Barcode,
        decimal TotalQuantitySold,
        decimal TotalRevenue)
    {
        public string Name => !string.IsNullOrWhiteSpace(ProductName) ? ProductName : "منتج بدون اسم";
    }

    public record ExpenseDto(Guid Id, string Title, string? Description, string? Category, decimal Amount, DateTime ExpenseDate, string? Notes)
    {
        public string DisplayCategory => !string.IsNullOrWhiteSpace(Category)
            ? Category
            : (!string.IsNullOrWhiteSpace(Description) ? Description : "عام");
    }
    public record CreateExpenseRequest(string Title, decimal Amount, Guid CreatedByUserId, string? Description = null, DateTime? ExpenseDate = null, string? Notes = null);

    public record CreateSupplierRequest(string Name, string Phone, string? Email = null, string? Address = null, string? ContactPerson = null, Guid? Id = null);
    public record UpdateSupplierRequest(Guid Id, string Name, string Phone, string? Email = null, string? Address = null, string? ContactPerson = null);

    public record PurchaseItemDto(Guid Id, Guid ProductId, string? ProductName, decimal Quantity, decimal UnitCost, decimal Discount, decimal Tax, decimal Total, DateTime? ExpiryDate, string? BatchNumber)
    {
        public decimal UnitCostPrice => UnitCost;
        public decimal TotalCost => Total;
    }
    public record ExpiringProductDto(
        Guid ProductId,
        string ProductName,
        string Barcode,
        DateTime ExpiryDate,
        string? BatchNumber,
        decimal QuantityInStock,
        string? InvoiceNumber,
        string? SupplierName,
        int DaysRemaining,
        Guid BatchId = default,
        decimal BatchRemainingQuantity = 0,
        decimal BatchOriginalQuantity = 0,
        decimal TotalProductStock = 0,
        decimal UnitCost = 0,
        DateTime? PurchaseDate = null,
        bool IsDepleted = false,
        decimal WastedQuantity = 0);
    public record PurchaseDto(Guid Id, string InvoiceNumber, DateTime PurchaseDate, Guid SupplierId, string? SupplierName, decimal TotalAmount, decimal PaidAmount, decimal RemainingAmount, string Status, string? Notes, List<PurchaseItemDto>? Items);
    public record CreatePurchaseItemRequest(Guid ProductId, decimal Quantity, decimal UnitCost, decimal Discount = 0, decimal Tax = 0, DateTime? ExpiryDate = null, string? BatchNumber = null, string? Unit = null)
    {
        public decimal UnitCostPrice => UnitCost;
    }
    public record CreatePurchaseRequest(string InvoiceNumber, Guid SupplierId, Guid CreatedByUserId, List<CreatePurchaseItemRequest> Items, string? InternalNumber = null, decimal DiscountAmount = 0, decimal TaxAmount = 0, decimal PaidAmount = 0, int PaymentMethod = 1, string? Notes = null, DateTime? PurchaseDate = null);
    public record UpdatePurchaseRequest(Guid Id, string InvoiceNumber, Guid SupplierId, Guid UserId, List<CreatePurchaseItemRequest> Items, string? InternalNumber = null, decimal DiscountAmount = 0, decimal TaxAmount = 0, decimal PaidAmount = 0, int PaymentMethod = 1, string? Notes = null, DateTime? PurchaseDate = null);

    public record PurchaseDetailItemDto(
        Guid Id,
        Guid ProductId,
        string? ProductName,
        string? Barcode,
        decimal Quantity,
        decimal UnitCost,
        decimal Discount,
        decimal Tax,
        decimal Total,
        DateTime? ExpiryDate,
        string? BatchNumber,
        decimal ReturnedQuantity = 0,
        decimal RemainingQuantity = 0,
        string? BaseUnit = "قطعة",
        string? ParentUnit = "كرتونة",
        int ConversionFactor = 1)
    {
        public decimal UnitCostPrice => UnitCost;
    }
    public record PurchaseDetailDto(Guid Id, string InvoiceNumber, string? InternalNumber, DateTime PurchaseDate, Guid SupplierId, string? SupplierName, decimal SubTotal, decimal DiscountAmount, decimal TaxAmount, decimal TotalAmount, decimal PaidAmount, decimal RemainingAmount, string Status, string? Notes, List<PurchaseDetailItemDto> Items);

    public class SaleItemDto
    {
        public Guid Id { get; set; }
        public Guid ProductId { get; set; }
        public string? ProductName { get; set; }
        public string? Barcode { get; set; }
        public decimal Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Discount { get; set; }
        public decimal Tax { get; set; }
        public decimal Total { get; set; }
        public decimal ReturnedQuantity { get; set; } = 0;
        public decimal RemainingQuantity { get; set; } = 0;
        public string? BaseUnit { get; set; } = "قطعة";
        public string? ParentUnit { get; set; } = "كرتونة";
        public int ConversionFactor { get; set; } = 1;
        public string? UnitName { get; set; }
        public string? PriceType { get; set; }
        public string? PackagingInfo { get; set; }
        public string? SerialNumber { get; set; }
        public string? BrandName { get; set; }
        public string? ModelNumber { get; set; }
        public int WarrantyPeriodMonths { get; set; } = 0;
        public string? MaintenanceAgent { get; set; }
    }

    public class SaleDto
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
        public List<SaleItemDto>? Items { get; set; } = new();
        public bool IsReserved { get; set; } = false;
        public DateTime? TargetDeliveryDate { get; set; }
        public int ReservationStatus { get; set; } = 0;
        public bool IsDelivery { get; set; } = false;
        public string? RecipientName { get; set; }
        public string? RecipientPhone { get; set; }
        public string? DeliveryAddress { get; set; }
        public string? DeliveryFloor { get; set; }
        public string? DriverName { get; set; }
        public int DeliveryStatus { get; set; } = 0;
        public bool IsInstallment { get; set; } = false;
        public Guid? InstallmentContractId { get; set; }
        public decimal RemainingAmount => Math.Max(0, TotalAmount - PaidAmount);
    }

    public record StoreSettingDto(
        Guid Id,
        string StoreName,
        string? Address,
        string? Phone,
        decimal TaxRate,
        bool IsTaxIncluded,
        string Currency,
        string? InvoiceFooterMessage,
        bool AllowNegativeStock,
        bool AutoPrintInvoice,
        bool EnableDepletedBatchAlert,
        string? LogoUrl,
        string? HeaderImageUrl,
        string? FooterImageUrl,
        DateTime UpdatedAt);

    public record UpdateStoreSettingRequest(
        string StoreName,
        string? Address,
        string? Phone,
        decimal TaxRate,
        bool IsTaxIncluded,
        string Currency,
        string? InvoiceFooterMessage,
        bool AllowNegativeStock,
        bool AutoPrintInvoice = true,
        string? LogoUrl = null,
        bool EnableDepletedBatchAlert = true,
        string? HeaderImageUrl = null,
        string? FooterImageUrl = null);

    public record AuditLogDto(
        Guid Id,
        Guid? UserId,
        string Action,
        string EntityName,
        Guid? EntityId,
        string? OldValues,
        string? NewValues,
        string? IpAddress,
        DateTime CreatedAt);

    public record OnlineProductLookupResult(string Barcode, string? NameAr, string? NameEn, string? ImageUrl, byte[]? ImageBytes);

    // Returns DTOs
    public record SalesReturnItemRequest(
        Guid ProductId,
        Guid OriginalSaleItemId,
        decimal Quantity,
        decimal UnitPrice,
        decimal Tax = 0,
        string? Reason = null);

    public record CreateSalesReturnRequest(
        Guid OriginalSaleId,
        Guid CashierId,
        Guid ShiftId,
        List<SalesReturnItemRequest> Items,
        Guid? CustomerId = null,
        int RefundMethod = 1,
        string? Reason = null,
        string? Notes = null);

    public record SalesReturnDto(
        Guid Id,
        string ReturnNumber,
        Guid OriginalSaleId,
        Guid CashierId,
        string? CashierName,
        Guid? CustomerId,
        string? CustomerName,
        Guid ShiftId,
        DateTime ReturnDate,
        decimal SubTotal,
        decimal TaxAmount,
        decimal TotalAmount,
        string RefundMethod,
        string? Reason,
        string? Notes,
        string Status);

    public record SalesReturnDetailItemDto(
        Guid Id,
        Guid ProductId,
        string? ProductName,
        string? Barcode,
        Guid OriginalSaleItemId,
        decimal Quantity,
        decimal UnitPrice,
        decimal Tax,
        decimal Total,
        string? Reason);

    public record SalesReturnDetailDto(
        Guid Id,
        string ReturnNumber,
        Guid OriginalSaleId,
        string? OriginalInvoiceNumber,
        Guid CashierId,
        string? CashierName,
        Guid? CustomerId,
        string? CustomerName,
        Guid ShiftId,
        DateTime ReturnDate,
        decimal SubTotal,
        decimal TaxAmount,
        decimal TotalAmount,
        string RefundMethod,
        string? Reason,
        string? Notes,
        string Status,
        List<SalesReturnDetailItemDto>? Items = null);

    public record UpdateSalesReturnRequest(
        Guid Id,
        int RefundMethod,
        string? Reason,
        string? Notes,
        List<SalesReturnItemRequest> Items,
        Guid UserId);

    public record PurchaseReturnItemRequest(
        Guid ProductId,
        decimal Quantity,
        decimal UnitCost,
        decimal Tax = 0);

    public record CreatePurchaseReturnRequest(
        Guid OriginalPurchaseId,
        Guid SupplierId,
        Guid CreatedByUserId,
        List<PurchaseReturnItemRequest> Items,
        string? Reason = null,
        string? Notes = null);

    public record PurchaseReturnDto(
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

    public record PurchaseReturnDetailItemDto(
        Guid Id,
        Guid ProductId,
        string? ProductName,
        string? Barcode,
        decimal Quantity,
        decimal UnitCost,
        decimal Tax,
        decimal Total);

    public record PurchaseReturnDetailDto(
        Guid Id,
        string ReturnNumber,
        Guid OriginalPurchaseId,
        string? OriginalInvoiceNumber,
        Guid SupplierId,
        string? SupplierName,
        DateTime ReturnDate,
        decimal SubTotal,
        decimal TaxAmount,
        decimal TotalAmount,
        string? Reason,
        string? Notes,
        string Status,
        Guid CreatedByUserId,
        string? CreatedByUserName = null,
        List<PurchaseReturnDetailItemDto>? Items = null);

    public record UpdatePurchaseReturnRequest(
        Guid Id,
        string? Reason,
        string? Notes,
        List<PurchaseReturnItemRequest> Items,
        Guid UserId);

    // Debts DTOs
    public class CustomerDebtDto
    {
        public Guid SaleId { get; set; }
        public string InvoiceNumber { get; set; } = string.Empty;
        public DateTime SaleDate { get; set; }
        public Guid? CustomerId { get; set; }
        public string? CustomerName { get; set; }
        public string? CustomerPhone { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public string PaymentMethod { get; set; } = "Cash";
        public string Status { get; set; } = "Completed";
    }

    public class SupplierDebtDto
    {
        public Guid PurchaseId { get; set; }
        public string InvoiceNumber { get; set; } = string.Empty;
        public DateTime PurchaseDate { get; set; }
        public Guid SupplierId { get; set; }
        public string? SupplierName { get; set; }
        public string? SupplierPhone { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    // Monthly Sales Calendar DTOs
    public record MonthlyDaySalesDto(
        int DayNumber,
        DateTime Date,
        int DayOfWeekIndex,
        string DayNameAr,
        decimal TotalSales,
        int InvoiceCount,
        decimal TotalReturns,
        decimal NetSales,
        decimal TotalPaid,
        decimal TotalExpenses,
        decimal TotalPurchases,
        bool HasSales,
        bool IsToday,
        bool IsWeekend,
        decimal CashSales = 0,
        decimal CreditSales = 0,
        decimal DebtCollections = 0);

    public record MonthlySalesCalendarDto(
        int Year,
        int Month,
        string MonthNameAr,
        int DaysInMonth,
        int FirstDayDayOfWeek,
        decimal TotalMonthlySales,
        int TotalMonthlyInvoices,
        decimal TotalMonthlyReturns,
        decimal NetMonthlySales,
        decimal TotalMonthlyExpenses,
        decimal TotalMonthlyPurchases,
        decimal DailyAverageSales,
        decimal DailyAverageSalesActiveDays,
        int ActiveDaysCount,
        int HighestSalesDay,
        decimal HighestSalesAmount,
        int LowestSalesDay,
        decimal LowestSalesAmount,
        List<MonthlyDaySalesDto> Days,
        decimal TotalMonthlyCashSales = 0,
        decimal TotalMonthlyCreditSales = 0,
        decimal TotalMonthlyDebtCollections = 0,
        decimal TotalMonthlyCollected = 0);

    public record DayInvoiceSummaryDto(
        Guid Id,
        string InvoiceNumber,
        DateTime SaleDate,
        Guid CashierId,
        string CashierName,
        Guid? CustomerId,
        string CustomerName,
        decimal SubTotal,
        decimal DiscountAmount,
        decimal TaxAmount,
        decimal TotalAmount,
        decimal PaidAmount,
        string PaymentMethod,
        int Status,
        int ItemCount,
        string? Notes);

    public record DaySalesDetailsDto(
        DateTime Date,
        string DayNameAr,
        decimal TotalSales,
        int TotalInvoices,
        decimal TotalReturns,
        decimal TotalExpenses,
        decimal TotalPurchases,
        List<DayInvoiceSummaryDto> Invoices);

    // Batch DTOs
    public record ProductBatchDto(
        Guid Id,
        Guid ProductId,
        string BatchNumber,
        decimal OriginalQuantity,
        string OriginalUnit,
        decimal BaseQuantity,
        decimal RemainingQuantity,
        decimal RemainingInParentUnit,
        decimal UnitCost,
        decimal CartonCost,
        DateTime PurchaseDate,
        DateTime? ExpiryDate,
        int? DaysUntilExpiry,
        string Status);

    // Expiry Notification DTOs
    public record ExpiryNotificationDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string ProductBarcode,
        Guid BatchId,
        string BatchNumber,
        decimal RemainingQuantity,
        string BaseUnit,
        string? ParentUnit,
        int ConversionFactor,
        decimal UnitCost,
        DateTime? ExpiryDate,
        int DaysRemaining,
        bool IsExpired,
        string Message,
        string Status,
        DateTime CreatedAt);

    public record SnoozeNotificationRequest(int Hours = 24);

    // Waste DTOs
    public record RecordWasteRequest(
        Guid ProductId,
        Guid InventoryBatchId,
        decimal Quantity,
        string Unit,
        string Reason,
        string? Notes = null,
        string Source = "Manual",
        Guid? RelatedNotificationId = null);

    public record WasteItemDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string ProductBarcode,
        Guid InventoryBatchId,
        string BatchNumber,
        decimal Quantity,
        string Unit,
        decimal BaseQuantity,
        decimal UnitCost,
        decimal TotalCost,
        string Reason,
        string Source,
        string? Notes,
        DateTime CreatedAt);

    public record WasteReportResponse(
        List<WasteItemDto> Items,
        decimal TotalLossAmount,
        int TotalRecordsCount);

    // Price Update DTO
    public record ApplyProductPricesRequest(
        decimal CostPrice,
        decimal SellingPrice,
        decimal WholesalePrice);

    // ==========================================
    // Home Appliances Domain Models
    // ==========================================

    // Brands
    public record BrandDto
    {
        public Guid Id { get; init; }
        public string? Name { get; init; }
        private string? _nameAr;
        public string NameAr
        {
            get => !string.IsNullOrWhiteSpace(_nameAr) ? _nameAr : (Name ?? "");
            init => _nameAr = value;
        }
        public string? NameEn { get; init; }
        public string? Description { get; init; }
        public string? OriginCountry { get; init; }
        public string? AgentContactNumber { get; init; }
        public bool IsActive { get; init; } = true;
        public DateTime CreatedAt { get; init; }
    }

    public record CreateBrandRequest(
        string? NameAr = null,
        string? NameEn = null,
        string? Description = null,
        string? OriginCountry = null,
        string? AgentContactNumber = null,
        string? Name = null);

    public record UpdateBrandRequest(
        Guid Id,
        string? NameAr = null,
        string? NameEn = null,
        string? Description = null,
        string? OriginCountry = null,
        string? AgentContactNumber = null,
        bool IsActive = true,
        string? Name = null);

    // Product Serials
    public class ProductSerialDto
    {
        public Guid Id { get; set; }
        public Guid ProductId { get; set; }
        public string? ProductName { get; set; }
        public string SerialNumber { get; set; } = string.Empty;
        public int Status { get; set; }         // 0=InStock, 1=Sold, 2=Returned, 3=Defective
        public string StatusText { get; set; } = string.Empty;  // Arabic label from SQL CASE
        public DateTime? SoldAt { get; set; }
        public DateTime? WarrantyExpiryDate { get; set; }
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public record AddProductSerialsRequest(
        Guid ProductId,
        List<string> SerialNumbers,
        string? Notes = null);

    // Installments
    public class InstallmentContractDto
    {
        public Guid Id { get; set; }
        public string ContractNumber { get; set; } = string.Empty;
        public Guid SaleId { get; set; }
        public string InvoiceNumber { get; set; } = string.Empty;
        public Guid CustomerId { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string? GuarantorName { get; set; }
        public string? GuarantorPhone { get; set; }
        public string? GuarantorNationalId { get; set; }
        public string? GuarantorAddress { get; set; }
        public string? GuarantorNotes { get; set; }
        public decimal TotalCashAmount { get; set; }
        public decimal DownPayment { get; set; }
        public decimal InterestPercentage { get; set; }
        public decimal InterestAmount { get; set; }
        public decimal TotalInstallmentAmount { get; set; }
        public decimal MonthlyInstallmentAmount { get; set; }
        public decimal TotalPaidAmount { get; set; }
        public decimal RemainingBalance { get; set; }
        public int NumberOfMonths { get; set; }
        public DateTime StartDate { get; set; }
        public int Status { get; set; }
        public string StatusText { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<InstallmentScheduleDto> Schedules { get; set; } = new();

        // Convenience / Compatibility getters
        public decimal TotalAmount => TotalCashAmount > 0 ? TotalCashAmount : TotalInstallmentAmount;
        public decimal TotalWithInterest => TotalInstallmentAmount;
        public decimal RemainingAmount => RemainingBalance;
        public decimal MonthlyAmount => MonthlyInstallmentAmount;
        public decimal InterestRate => InterestPercentage;
    }

    public class InstallmentScheduleDto
    {
        public Guid Id { get; set; }
        public Guid ContractId { get; set; }
        public int InstallmentNumber { get; set; }
        public DateTime DueDate { get; set; }
        public decimal Amount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public DateTime? PaidDate { get; set; }
        public int Status { get; set; }
        public string StatusText { get; set; } = string.Empty;
        public string? PaymentMethod { get; set; }
        public string? ReceiptNumber { get; set; }
        public string? Notes { get; set; }
    }

    public record PayInstallmentRequest(
        Guid ContractId,
        Guid ScheduleId,
        decimal Amount,
        string PaymentMethod = "Cash",
        Guid? CashierId = null,
        Guid? ShiftId = null,
        string? Notes = null);

    public class UpcomingInstallmentDto
    {
        public Guid ScheduleId { get; set; }
        public Guid ContractId { get; set; }
        public string ContractNumber { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string? GuarantorName { get; set; }
        public string? GuarantorPhone { get; set; }
        public int InstallmentNumber { get; set; }
        public DateTime DueDate { get; set; }
        public decimal Amount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public bool IsOverdue { get; set; }
        public int DaysOverdueOrRemaining { get; set; }
        public int DaysRemaining => DaysOverdueOrRemaining;
    }

    // Offers & Bundles
    public record OfferItemDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? ProductBarcode,
        decimal Quantity,
        decimal OriginalUnitPrice)
    {
        public decimal OriginalPrice => OriginalUnitPrice;
        public decimal SpecialPrice => OriginalUnitPrice;
    }

    public record OfferDto(
        Guid Id,
        string Title,
        string? Description,
        int Type,
        string TypeText,
        decimal? DiscountPercentage,
        decimal? FixedDiscountAmount,
        decimal? BundlePrice,
        DateTime StartDate,
        DateTime EndDate,
        bool IsActive,
        bool IsCurrentlyValid,
        Guid? TargetProductId,
        string? TargetProductName,
        Guid? TargetCategoryId,
        string? TargetCategoryName,
        Guid? TargetBrandId,
        string? TargetBrandName,
        DateTime CreatedAt,
        List<OfferItemDto>? Items)
    {
        public string TitleAr => Title;
        public string? TitleEn => null;
        public string OfferType => Type switch
        {
            0 => "ProductDiscount",
            1 => "CategoryDiscount",
            2 => "BrandDiscount",
            3 => "BundlePackage",
            _ => "Unknown"
        };
        public decimal DiscountPercent => DiscountPercentage ?? 0;
        public decimal DiscountAmount => FixedDiscountAmount ?? 0;
        public decimal PackagePrice => BundlePrice ?? 0;
    }

    public record CreateOfferItemRequest(
        Guid ProductId,
        decimal Quantity = 1);

    public record CreateOfferRequest(
        string Title,
        string? Description,
        int Type,
        decimal? DiscountPercentage,
        decimal? FixedDiscountAmount,
        decimal? BundlePrice,
        DateTime StartDate,
        DateTime EndDate,
        Guid? TargetCategoryId = null,
        Guid? TargetBrandId = null,
        List<CreateOfferItemRequest>? Items = null,
        string? TitleAr = null,
        Guid? TargetProductId = null);
}

