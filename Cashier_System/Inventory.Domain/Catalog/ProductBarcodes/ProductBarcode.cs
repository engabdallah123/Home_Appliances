using Inventory.Domain.Catalog.Products.Errors;
using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.ProductBarcodes
{
    public sealed class ProductBarcode : Entity
    {
        public Guid ProductId { get; private set; }
        public string Barcode { get; private set; } = default!;
        public bool IsDefault { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private ProductBarcode() { } // EF Core

        private ProductBarcode(Guid id, Guid productId, string barcode, bool isDefault)
            : base(id)
        {
            ProductId = productId;
            Barcode = barcode;
            IsDefault = isDefault;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<ProductBarcode> Create(Guid productId, string barcode, bool isDefault = false)
        {
            if (productId == Guid.Empty)
                return Result<ProductBarcode>.Failure(Error.EmptyId("Product"));

            if (string.IsNullOrWhiteSpace(barcode))
                return Result<ProductBarcode>.Failure(ProductBarcodeErrors.Empty);

            if (barcode.Trim().Length > 64)
                return Result<ProductBarcode>.Failure(ProductBarcodeErrors.TooLong);

            var entity = new ProductBarcode(Guid.NewGuid(), productId, barcode.Trim(), isDefault);
            return Result<ProductBarcode>.Success(entity);
        }

        public void SetAsDefault() => IsDefault = true;
        public void UnsetDefault() => IsDefault = false;
    }
}
