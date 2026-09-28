using POS.Shared.Domain;

namespace Sales.Domain.Sales.Entities
{
    public sealed class SaleItem : Entity
    {
        public Guid SaleId { get; private set; }
        public Guid ProductId { get; private set; }
        public decimal Quantity { get; private set; }
        public decimal UnitPrice { get; private set; }
        public decimal Discount { get; private set; }
        public decimal Tax { get; private set; }
        public decimal Total { get; private set; }
        public string? SerialNumber { get; private set; }

        private SaleItem() { } // EF Core

        private SaleItem(Guid id, Guid saleId, Guid productId, decimal quantity, decimal unitPrice, decimal discount, decimal tax, string? serialNumber = null)
            : base(id)
        {
            SaleId = saleId;
            ProductId = productId;
            Quantity = quantity;
            UnitPrice = unitPrice;
            Discount = discount;
            Tax = tax;
            Total = (quantity * unitPrice) - discount + tax;
            SerialNumber = serialNumber?.Trim();
        }

        public static Result<SaleItem> Create(Guid saleId, Guid productId, decimal quantity, decimal unitPrice, decimal discount = 0, decimal tax = 0, string? serialNumber = null)
        {
            if (productId == Guid.Empty)
                return Result<SaleItem>.Failure(SaleErrors.ProductIdRequired);

            if (quantity <= 0)
                return Result<SaleItem>.Failure(SaleErrors.InvalidQuantity);

            if (unitPrice < 0)
                return Result<SaleItem>.Failure(SaleErrors.InvalidUnitPrice);

            var item = new SaleItem(Guid.NewGuid(), saleId, productId, quantity, unitPrice, discount, tax, serialNumber);
            return Result<SaleItem>.Success(item);
        }

        public void SetSerialNumber(string? serialNumber)
        {
            SerialNumber = serialNumber?.Trim();
        }
    }
}
