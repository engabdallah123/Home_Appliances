using POS.Shared.Domain;

namespace Purchases.Domain.Purchases
{
    public static class PurchaseErrors
    {
        public static Error NotFound(Guid id) =>
            new("Purchase.NotFound", $"فاتورة الشراء بالرقم '{id}' غير موجودة.");

        public static readonly Error InvoiceNumberRequired =
            new("Purchase.InvoiceNumberRequired", "رقم الفاتورة مطلوب.");

        public static readonly Error SupplierIdRequired =
            new("Purchase.SupplierIdRequired", "معرف المورد مطلوب.");

        public static readonly Error CreatedByRequired =
            new("Purchase.CreatedByRequired", "معرف المستخدم المنشئ مطلوب.");

        public static readonly Error ProductIdRequired =
            new("Purchase.ProductIdRequired", "معرف المنتج مطلوب.");

        public static readonly Error InvalidQuantity =
            new("Purchase.InvalidQuantity", "الكمية يجب أن تكون أكبر من صفر.");

        public static readonly Error InvalidUnitCost =
            new("Purchase.InvalidUnitCost", "تكلفة الوحدة لا يمكن أن تكون سالبة.");

        public static readonly Error OnlyDraftCanBeModified =
            new("Purchase.OnlyDraftCanBeModified", "يمكن تعديل الفواتير في حالة المسودة فقط.");

        public static readonly Error OnlyDraftCanBeReceived =
            new("Purchase.OnlyDraftCanBeReceived", "يمكن استلام الفواتير في حالة المسودة فقط.");

        public static readonly Error ReceivedCannotBeCancelled =
            new("Purchase.ReceivedCannotBeCancelled", "لا يمكن إلغاء فاتورة تم استلامها بالفعل.");

        public static readonly Error PurchaseHasNoItems =
            new("Purchase.PurchaseHasNoItems", "لا يمكن استلام فاتورة شراء بدون عناصر.");

        public static readonly Error PaymentAmountInvalid =
            new("Purchase.PaymentAmountInvalid", "مبلغ السداد يجب أن يكون أكبر من صفر.");

        public static readonly Error PaymentExceedsRemaining =
            new("Purchase.PaymentExceedsRemaining", "مبلغ السداد لا يمكن أن يتجاوز المبلغ المتبقي للفاتورة.");

        public static readonly Error PurchaseAlreadyFullyPaid =
            new("Purchase.PurchaseAlreadyFullyPaid", "الفاتورة مدفوعة بالكامل بالفعل.");
    }
}
