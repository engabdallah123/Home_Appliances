using POS.Shared.Domain;

namespace Inventory.Domain.Pricing.ProductPrices
{
    public sealed class ProductPrice : Entity
    {
        public Guid ProductId { get; private set; }
        public Guid PriceListId { get; private set; }
        public decimal Price { get; private set; }
        public string Currency { get; private set; } = "EGP";
        public DateTime CreatedAt { get; private set; }
        public DateTime? UpdatedAt { get; private set; }

        private ProductPrice() { } // EF Core

        private ProductPrice(Guid id, Guid productId, Guid priceListId, decimal price, string currency)
            : base(id)
        {
            ProductId = productId;
            PriceListId = priceListId;
            Price = price;
            Currency = currency;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<ProductPrice> Create(Guid productId, Guid priceListId, decimal price, string currency = "EGP")
        {
            if (productId == Guid.Empty)
                return Result<ProductPrice>.Failure(Error.EmptyId("Product"));

            if (priceListId == Guid.Empty)
                return Result<ProductPrice>.Failure(Error.EmptyId("PriceList"));

            if (price < 0)
                return Result<ProductPrice>.Failure(ProductPriceErrors.PriceCannotBeNegative);

            if (string.IsNullOrWhiteSpace(currency))
                return Result<ProductPrice>.Failure(ProductPriceErrors.CurrencyRequired);

            var productPrice = new ProductPrice(
                Guid.NewGuid(), productId, priceListId, price, currency.Trim().ToUpperInvariant());
            return Result<ProductPrice>.Success(productPrice);
        }

        public Result UpdatePrice(decimal newPrice)
        {
            if (newPrice < 0)
                return Result.Failure(ProductPriceErrors.PriceCannotBeNegative);

            Price = newPrice;
            UpdatedAt = DateTime.UtcNow;
            return Result.Success();
        }
    }
}
