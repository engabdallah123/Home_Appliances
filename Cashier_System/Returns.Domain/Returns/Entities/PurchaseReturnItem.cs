using POS.Shared.Domain;

namespace Returns.Domain.Returns.Entities
{
    public sealed class PurchaseReturnItem : Entity
    {
        public Guid PurchaseReturnId { get; private set; }
        public Guid ProductId { get; private set; }
        public decimal Quantity { get; private set; }
        public decimal UnitCost { get; private set; }
        public decimal Tax { get; private set; }
        public decimal Total { get; private set; }

        private PurchaseReturnItem() { } // EF Core

        private PurchaseReturnItem(Guid id, Guid purchaseReturnId, Guid productId, decimal quantity, decimal unitCost, decimal tax)
            : base(id)
        {
            PurchaseReturnId = purchaseReturnId;
            ProductId = productId;
            Quantity = quantity;
            UnitCost = unitCost;
            Tax = tax;
            Total = (quantity * unitCost) + tax;
        }

        public static Result<PurchaseReturnItem> Create(Guid purchaseReturnId, Guid productId, decimal quantity, decimal unitCost, decimal tax = 0)
        {
            if (productId == Guid.Empty)
                return Result<PurchaseReturnItem>.Failure(ReturnErrors.ProductIdRequired);

            if (quantity <= 0)
                return Result<PurchaseReturnItem>.Failure(ReturnErrors.InvalidQuantity);

            var item = new PurchaseReturnItem(Guid.NewGuid(), purchaseReturnId, productId, quantity, unitCost, tax);
            return Result<PurchaseReturnItem>.Success(item);
        }
    }
}
