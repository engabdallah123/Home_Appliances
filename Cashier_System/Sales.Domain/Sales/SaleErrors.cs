using POS.Shared.Domain;

namespace Sales.Domain.Sales
{
    public static class SaleErrors
    {
        public static Error NotFound(Guid id) =>
            new("Sale.NotFound", $"الفاتورة بالرقم '{id}' غير موجودة.");

        public static Error NotFoundByInvoiceNumber(string invoiceNumber) =>
            new("Sale.NotFoundByInvoiceNumber", $"لا توجد فاتورة برقم '{invoiceNumber}'.");

        public static readonly Error InvoiceNumberRequired =
            new("Sale.InvoiceNumberRequired", "رقم الفاتورة مطلوب.");

        public static readonly Error CashierIdRequired =
            new("Sale.CashierIdRequired", "معرف الكاشير مطلوب.");

        public static readonly Error ShiftIdRequired =
            new("Sale.ShiftIdRequired", "معرف الشفت مطلوب.");

        public static readonly Error ProductIdRequired =
            new("Sale.ProductIdRequired", "معرف المنتج مطلوب.");

        public static readonly Error InvalidQuantity =
            new("Sale.InvalidQuantity", "الكمية المباعة يجب أن تكون أكبر من صفر.");

        public static readonly Error InvalidUnitPrice =
            new("Sale.InvalidUnitPrice", "سعر الوحدة لا يمكن أن يكون سالباً.");

        public static readonly Error SaleHasNoItems =
            new("Sale.SaleHasNoItems", "لا يمكن إنهاء عملية بيع بدون عناصر.");

        public static readonly Error InsufficientPaidAmount =
            new("Sale.InsufficientPaidAmount", "المبلغ المدفوع غير كافٍ لإنهاء الفاتورة.");

        public static readonly Error AlreadyCancelled =
            new("Sale.AlreadyCancelled", "الفاتورة ملغاة بالفعل.");

        public static readonly Error NoOpenShiftAvailable =
            new("Sale.NoOpenShiftAvailable", "لا يمكن إتمام البيع بدون وجود شفت مفتوح للكاشير.");

        public static readonly Error CustomerRequiredForCredit =
            new("Sale.CustomerRequiredForCredit", "يجب تحديد عميل لتسجيل فاتورة بالآجل أو دفع جزء من المبلغ.");
    }
}
