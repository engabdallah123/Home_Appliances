using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockBalances
{
    public static class StockBalanceErrors
    {
        public static readonly Error QuantityMustBePositive =
            new("StockBalance.QuantityMustBePositive", "الكمية يجب أن تكون أكبر من صفر.");

        public static readonly Error InsufficientStock =
            new("StockBalance.InsufficientStock", "الكمية المتاحة غير كافية لإتمام العملية.");

        public static readonly Error AlreadyExists =
            Error.Conflict("StockBalance.AlreadyExists", "يوجد بالفعل رصيد لهذا المنتج في هذا المخزن.");

        public static Error NotFound(Guid productId, Guid warehouseId) =>
            new("StockBalance.NotFound", $"لا يوجد رصيد للمنتج '{productId}' في المخزن '{warehouseId}'.");
    }
}
