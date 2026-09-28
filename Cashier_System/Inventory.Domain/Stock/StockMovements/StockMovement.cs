using POS.Shared.Domain;

namespace Inventory.Domain.Stock.StockMovements
{
    public sealed class StockMovement : Entity
    {
        public Guid ProductId { get; private set; }
        public decimal Quantity { get; private set; }
        public StockMovementType Type { get; private set; }
        public string? Reference { get; private set; }
        public string? Notes { get; private set; }
        public DateTime MovementDate { get; private set; }
        public Guid UserId { get; private set; }

        private StockMovement() { } // EF Core

        private StockMovement(
            Guid id, Guid productId, decimal quantity, StockMovementType type,
            string? reference, string? notes, Guid userId)
            : base(id)
        {
            ProductId = productId;
            Quantity = quantity;
            Type = type;
            Reference = reference;
            Notes = notes;
            UserId = userId;
            MovementDate = DateTime.UtcNow;
        }

        public static Result<StockMovement> Create(
            Guid productId, decimal quantity, StockMovementType type,
            Guid userId, string? reference = null, string? notes = null)
        {
            if (productId == Guid.Empty)
                return Result<StockMovement>.Failure(StockMovementErrors.ProductIdRequired);

            if (quantity == 0)
                return Result<StockMovement>.Failure(StockMovementErrors.ZeroQuantity);

            if (userId == Guid.Empty)
                return Result<StockMovement>.Failure(StockMovementErrors.UserIdRequired);

            var movement = new StockMovement(
                Guid.NewGuid(), productId, quantity, type,
                reference?.Trim(), notes?.Trim(), userId);

            return Result<StockMovement>.Success(movement);
        }
    }
}
