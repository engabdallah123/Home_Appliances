using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockBalances
{
    public sealed class StockBalance : Entity
    {
        public Guid ProductId { get; private set; }
        public Guid WarehouseId { get; private set; }
        public int QuantityOnHand { get; private set; }
        public DateTime LastUpdated { get; private set; }

        private StockBalance() { } // EF Core

        private StockBalance(Guid id, Guid productId, Guid warehouseId)
            : base(id)
        {
            ProductId = productId;
            WarehouseId = warehouseId;
            QuantityOnHand = 0;
            LastUpdated = DateTime.UtcNow;
        }

        public static Result<StockBalance> Create(Guid productId, Guid warehouseId)
        {
            if (productId == Guid.Empty)
                return Result<StockBalance>.Failure(Error.EmptyId("Product"));

            if (warehouseId == Guid.Empty)
                return Result<StockBalance>.Failure(Error.EmptyId("Warehouse"));

            var balance = new StockBalance(Guid.NewGuid(), productId, warehouseId);
            return Result<StockBalance>.Success(balance);
        }

        public Result Increase(int quantity)
        {
            if (quantity <= 0)
                return Result.Failure(StockBalanceErrors.QuantityMustBePositive);

            QuantityOnHand += quantity;
            LastUpdated = DateTime.UtcNow;
            return Result.Success();
        }

        public Result Decrease(int quantity, bool allowNegative = false)
        {
            if (quantity <= 0)
                return Result.Failure(StockBalanceErrors.QuantityMustBePositive);

            if (!allowNegative && QuantityOnHand < quantity)
                return Result.Failure(StockBalanceErrors.InsufficientStock);

            QuantityOnHand -= quantity;
            LastUpdated = DateTime.UtcNow;
            return Result.Success();
        }

        public Result SetQuantity(int quantity)
        {
            QuantityOnHand = quantity;
            LastUpdated = DateTime.UtcNow;
            return Result.Success();
        }
    }
}
