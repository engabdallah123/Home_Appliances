using POS.Shared.Application.Messaging;

namespace Sales.Application.Sales.Commands.CreateSale
{
    public sealed record CreateSaleItemRequest(
        Guid ProductId,
        decimal Quantity,
        decimal UnitPrice,
        decimal Discount = 0,
        decimal Tax = 0,
        string? SerialNumber = null);

    public sealed record CreateSaleCommand(
        Guid CashierId,
        Guid ShiftId,
        List<CreateSaleItemRequest> Items,
        Guid? CustomerId = null,
        decimal DiscountAmount = 0,
        decimal TaxAmount = 0,
        decimal PaidAmount = 0,
        string PaymentMethod = "Cash",
        string? Notes = null,
        // Delivery details
        bool IsDelivery = false,
        string? RecipientName = null,
        string? RecipientPhone = null,
        string? DeliveryAddress = null,
        string? DeliveryFloor = null,
        decimal DeliveryFee = 0,
        string? DriverName = null,
        // Reservation details (جهاز عروسة)
        bool IsReserved = false,
        DateTime? TargetDeliveryDate = null,
        // Installment details
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
        bool BypassStockCheck = false) : ICommand<CreateSaleResult>;
}
