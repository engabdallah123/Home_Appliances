using POS.Shared.Domain;

namespace Inventory.Domain.Pricing.ProductPrices
{
    public static class ProductPriceErrors
    {
        public static readonly Error PriceCannotBeNegative =
            new("ProductPrice.PriceCannotBeNegative", "السعر لا يمكن أن يكون سالبًا.");

        public static readonly Error CurrencyRequired =
            new("ProductPrice.CurrencyRequired", "العملة مطلوبة.");

        public static readonly Error AlreadyExists =
            Error.Conflict("ProductPrice.AlreadyExists", "يوجد بالفعل سعر لهذا المنتج في قائمة الأسعار.");

        public static Error NotFound(Guid productId, Guid priceListId) =>
            new("ProductPrice.NotFound", $"لا يوجد سعر للمنتج '{productId}' في قائمة الأسعار '{priceListId}'.");
    }
}
