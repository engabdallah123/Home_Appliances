using POS.Shared.Domain;

namespace Returns.Domain.Returns
{
    public static class ReturnErrors
    {
        public static Error NotFound(Guid id) =>
            new("Return.NotFound", $"عملية المرتجع بالرقم '{id}' غير موجودة.");

        public static readonly Error ReturnNumberRequired =
            new("Return.ReturnNumberRequired", "رقم المرتجع مطلوب.");

        public static readonly Error OriginalSaleIdRequired =
            new("Return.OriginalSaleIdRequired", "معرف الفاتورة الأصلية مطلوب.");

        public static readonly Error OriginalPurchaseIdRequired =
            new("Return.OriginalPurchaseIdRequired", "معرف فاتورة الشراء الأصلية مطلوب.");

        public static readonly Error CashierIdRequired =
            new("Return.CashierIdRequired", "معرف الكاشير مطلوب.");

        public static readonly Error ShiftIdRequired =
            new("Return.ShiftIdRequired", "معرف الشفت مطلوب.");

        public static readonly Error SupplierIdRequired =
            new("Return.SupplierIdRequired", "معرف المورد مطلوب.");

        public static readonly Error ProductIdRequired =
            new("Return.ProductIdRequired", "معرف المنتج مطلوب.");

        public static readonly Error InvalidQuantity =
            new("Return.InvalidQuantity", "كمية المرتجع يجب أن تكون أكبر من صفر.");

        public static readonly Error ReturnHasNoItems =
            new("Return.ReturnHasNoItems", "لا يمكن إتمام المرتجع بدون عناصر.");
    }
}
