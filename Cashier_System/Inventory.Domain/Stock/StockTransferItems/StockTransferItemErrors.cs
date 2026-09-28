using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockTransferItems
{
    public static class StockTransferItemErrors
    {
        public static readonly Error QuantityMustBePositive =
            new("StockTransferItem.QuantityMustBePositive", "الكمية يجب أن تكون أكبر من صفر.");
    }
}
