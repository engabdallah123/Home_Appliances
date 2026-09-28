using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockMovements
{
    public static class StockMovementErrors
    {
        public static Error NotFound(Guid id) =>
            new("StockMovement.NotFound", $"حركة المخزون بالرقم '{id}' غير موجودة.");

        public static readonly Error ProductIdRequired =
            new("StockMovement.ProductIdRequired", "معرف المنتج مطلوب.");

        public static readonly Error UserIdRequired =
            new("StockMovement.UserIdRequired", "معرف المستخدم مطلوب.");

        public static readonly Error ZeroQuantity =
            new("StockMovement.ZeroQuantity", "كمية الحركة لا يمكن أن تكون صفرًا.");
    }
}
