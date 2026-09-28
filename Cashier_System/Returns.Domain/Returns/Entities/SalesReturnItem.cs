using POS.Shared.Domain;

namespace Returns.Domain.Returns.Entities
{
    public sealed class SalesReturnItem : Entity
    {
        public Guid SalesReturnId { get; private set; }
        public Guid ProductId { get; private set; }
        public Guid OriginalSaleItemId { get; private set; }
        public decimal Quantity { get; private set; }
        public decimal UnitPrice { get; private set; }
        public decimal Tax { get; private set; }
        public decimal Total { get; private set; }
        public string? Reason { get; private set; }

        private SalesReturnItem() { } // EF Core

        private SalesReturnItem(
            Guid id, Guid salesReturnId, Guid productId, Guid originalSaleItemId,
            decimal quantity, decimal unitPrice, decimal tax, string? reason)
            : base(id)
        {
            SalesReturnId = salesReturnId;
            ProductId = productId;
            OriginalSaleItemId = originalSaleItemId;
            Quantity = quantity;
            UnitPrice = unitPrice;
            Tax = tax;
            Total = (quantity * unitPrice) + tax;
            Reason = reason;
        }

        public static Result<SalesReturnItem> Create(
            Guid salesReturnId, Guid productId, Guid originalSaleItemId,
            decimal quantity, decimal unitPrice, decimal tax = 0, string? reason = null)
        {
            if (productId == Guid.Empty)
                return Result<SalesReturnItem>.Failure(ReturnErrors.ProductIdRequired);

            if (quantity <= 0)
                return Result<SalesReturnItem>.Failure(ReturnErrors.InvalidQuantity);

            var item = new SalesReturnItem(
                Guid.NewGuid(), salesReturnId, productId, originalSaleItemId,
                quantity, unitPrice, tax, reason?.Trim());

            return Result<SalesReturnItem>.Success(item);
        }
    }
}
