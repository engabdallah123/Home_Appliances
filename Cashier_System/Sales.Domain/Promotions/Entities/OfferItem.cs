using POS.Shared.Domain;

namespace Sales.Domain.Promotions.Entities
{
    public sealed class OfferItem : Entity
    {
        public Guid OfferId { get; private set; }
        public Guid ProductId { get; private set; }
        public decimal Quantity { get; private set; }

        private OfferItem() { } // EF Core

        private OfferItem(Guid id, Guid offerId, Guid productId, decimal quantity) : base(id)
        {
            OfferId = offerId;
            ProductId = productId;
            Quantity = quantity;
        }

        public static Result<OfferItem> Create(Guid offerId, Guid productId, decimal quantity = 1)
        {
            if (productId == Guid.Empty)
                return Result<OfferItem>.Failure(new Error("OfferItem.ProductIdRequired", "معرف المنتج في العرض مطلوب."));

            if (quantity <= 0)
                return Result<OfferItem>.Failure(new Error("OfferItem.InvalidQuantity", "كمية الصنف في العرض يجب أن تكون أكبر من صفر."));

            var item = new OfferItem(Guid.NewGuid(), offerId, productId, quantity);
            return Result<OfferItem>.Success(item);
        }
    }
}
