using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockTransfers
{
    public static class StockTransferErrors
    {
        public static Error NotFound(Guid id) =>
            new("StockTransfer.NotFound", $"التحويل بالرقم '{id}' غير موجود.");

        public static readonly Error TransferNumberRequired =
            new("StockTransfer.TransferNumberRequired", "رقم التحويل مطلوب.");

        public static readonly Error SameWarehouse =
            new("StockTransfer.SameWarehouse", "لا يمكن التحويل من المخزن إلى نفسه.");

        public static readonly Error CreatedByRequired =
            new("StockTransfer.CreatedByRequired", "بيانات المستخدم المنشئ للتحويل مطلوبة.");

        public static readonly Error CannotModifyNonDraft =
            new("StockTransfer.CannotModifyNonDraft", "لا يمكن تعديل تحويل غير مسودة.");

        public static readonly Error QuantityMustBePositive =
            new("StockTransfer.QuantityMustBePositive", "الكمية يجب أن تكون أكبر من صفر.");

        public static readonly Error DuplicateProduct =
            Error.Conflict("StockTransfer.DuplicateProduct", "المنتج موجود بالفعل في التحويل.");

        public static readonly Error CannotExecute =
            new("StockTransfer.CannotExecute", "لا يمكن تنفيذ التحويل في حالته الحالية.");

        public static readonly Error NoItems =
            new("StockTransfer.NoItems", "لا يمكن تنفيذ تحويل بدون أصناف.");

        public static readonly Error CannotCancelExecuted =
            new("StockTransfer.CannotCancelExecuted", "لا يمكن إلغاء تحويل تم تنفيذه.");
    }
}
