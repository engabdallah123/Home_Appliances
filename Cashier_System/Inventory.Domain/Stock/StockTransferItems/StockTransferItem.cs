using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockTransferItems
{
    public sealed class StockTransferItem : Entity
    {
        public Guid StockTransferId { get; private set; }
        public Guid ProductId { get; private set; }
        public int Quantity { get; private set; }

        private StockTransferItem() { } // EF Core

        private StockTransferItem(Guid id, Guid stockTransferId, Guid productId, int quantity)
            : base(id)
        {
            StockTransferId = stockTransferId;
            ProductId = productId;
            Quantity = quantity;
        }

        public static Result<StockTransferItem> Create(Guid stockTransferId, Guid productId, int quantity)
        {
            if (stockTransferId == Guid.Empty)
                return Result<StockTransferItem>.Failure(Error.EmptyId("StockTransfer"));

            if (productId == Guid.Empty)
                return Result<StockTransferItem>.Failure(Error.EmptyId("Product"));

            if (quantity <= 0)
                return Result<StockTransferItem>.Failure(StockTransferItemErrors.QuantityMustBePositive);

            var item = new StockTransferItem(Guid.NewGuid(), stockTransferId, productId, quantity);
            return Result<StockTransferItem>.Success(item);
        }
    }
}
