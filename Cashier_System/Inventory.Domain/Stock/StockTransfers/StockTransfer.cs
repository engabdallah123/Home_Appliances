using Inventory.Domain.Stock.StockTransferItems;
using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;

namespace Inventory.Domain.Stock.StockTransfers
{
    public sealed class StockTransfer : Entity
    {
        public string TransferNumber { get; private set; } = default!;
        public Guid SourceWarehouseId { get; private set; }
        public Guid DestinationWarehouseId { get; private set; }
        public TransferStatus Status { get; private set; }
        public string? Notes { get; private set; }
        public string CreatedBy { get; private set; } = default!;
        public DateTime CreatedAt { get; private set; }
        public DateTime? ExecutedAt { get; private set; }

        private readonly List<StockTransferItem> _items = new();
        public IReadOnlyList<StockTransferItem> Items => _items.AsReadOnly();

        private StockTransfer() { } // EF Core

        private StockTransfer(Guid id, string transferNumber, Guid sourceWarehouseId,
            Guid destinationWarehouseId, string createdBy, string? notes)
            : base(id)
        {
            TransferNumber = transferNumber;
            SourceWarehouseId = sourceWarehouseId;
            DestinationWarehouseId = destinationWarehouseId;
            Status = TransferStatus.Draft;
            CreatedBy = createdBy;
            Notes = notes;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<StockTransfer> Create(
            string transferNumber,
            Guid sourceWarehouseId,
            Guid destinationWarehouseId,
            string createdBy,
            string? notes = null)
        {
            if (string.IsNullOrWhiteSpace(transferNumber))
                return Result<StockTransfer>.Failure(StockTransferErrors.TransferNumberRequired);

            if (sourceWarehouseId == Guid.Empty)
                return Result<StockTransfer>.Failure(Error.EmptyId("SourceWarehouse"));

            if (destinationWarehouseId == Guid.Empty)
                return Result<StockTransfer>.Failure(Error.EmptyId("DestinationWarehouse"));

            if (sourceWarehouseId == destinationWarehouseId)
                return Result<StockTransfer>.Failure(StockTransferErrors.SameWarehouse);

            if (string.IsNullOrWhiteSpace(createdBy))
                return Result<StockTransfer>.Failure(StockTransferErrors.CreatedByRequired);

            var transfer = new StockTransfer(
                Guid.NewGuid(), transferNumber.Trim(), sourceWarehouseId,
                destinationWarehouseId, createdBy.Trim(), notes?.Trim());

            return Result<StockTransfer>.Success(transfer);
        }

        public Result AddItem(Guid productId, int quantity)
        {
            if (Status != TransferStatus.Draft)
                return Result.Failure(StockTransferErrors.CannotModifyNonDraft);

            if (productId == Guid.Empty)
                return Result.Failure(Error.EmptyId("Product"));

            if (quantity <= 0)
                return Result.Failure(StockTransferErrors.QuantityMustBePositive);

            // لا نضيف نفس المنتج مرتين
            if (_items.Any(i => i.ProductId == productId))
                return Result.Failure(StockTransferErrors.DuplicateProduct);

            var itemResult = StockTransferItem.Create(Id, productId, quantity);
            if (itemResult.IsFailure)
                return Result.Failure(itemResult.Error);

            _items.Add(itemResult.Value!);
            return Result.Success();
        }

        public Result Execute()
        {
            if (Status != TransferStatus.Draft && Status != TransferStatus.Pending)
                return Result.Failure(StockTransferErrors.CannotExecute);

            if (!_items.Any())
                return Result.Failure(StockTransferErrors.NoItems);

            Status = TransferStatus.Executed;
            ExecutedAt = DateTime.UtcNow;

            RaiseDomainEvent(new Events.StockTransferExecutedDomainEvent(
                Id, SourceWarehouseId, DestinationWarehouseId));

            return Result.Success();
        }

        public Result Cancel()
        {
            if (Status == TransferStatus.Executed)
                return Result.Failure(StockTransferErrors.CannotCancelExecuted);

            Status = TransferStatus.Cancelled;
            return Result.Success();
        }
    }
}
