using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Products.Entities
{
    public sealed class ProductSerial : Entity
    {
        public Guid ProductId { get; private set; }
        public string SerialNumber { get; private set; } = default!;
        public ProductSerialStatus Status { get; private set; }
        public Guid? PurchaseId { get; private set; }
        public Guid? SaleId { get; private set; }
        public DateTime? SoldAt { get; private set; }
        public DateTime? WarrantyExpiryDate { get; private set; }
        public string? Notes { get; private set; }
        public DateTime CreatedAt { get; private set; }
        public DateTime? UpdatedAt { get; private set; }

        private ProductSerial() { } // EF Core

        private ProductSerial(
            Guid id,
            Guid productId,
            string serialNumber,
            Guid? purchaseId = null,
            string? notes = null) : base(id)
        {
            ProductId = productId;
            SerialNumber = serialNumber.Trim();
            Status = ProductSerialStatus.InStock;
            PurchaseId = purchaseId;
            Notes = notes?.Trim();
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<ProductSerial> Create(
            Guid productId,
            string serialNumber,
            Guid? purchaseId = null,
            string? notes = null)
        {
            if (productId == Guid.Empty)
                return Result<ProductSerial>.Failure(new Error("ProductSerial.ProductIdRequired", "معرف المنتج مطلوب."));

            if (string.IsNullOrWhiteSpace(serialNumber))
                return Result<ProductSerial>.Failure(new Error("ProductSerial.NumberRequired", "الرقم التسلسلي (السيريال) مطلوب."));

            var serial = new ProductSerial(Guid.NewGuid(), productId, serialNumber, purchaseId, notes);
            return Result<ProductSerial>.Success(serial);
        }

        public Result MarkAsSold(Guid saleId, int warrantyPeriodMonths = 12)
        {
            if (Status == ProductSerialStatus.Sold)
                return Result.Failure(new Error("ProductSerial.AlreadySold", $"الرقم التسلسلي '{SerialNumber}' مباع بالفعل مسبقاً."));

            Status = ProductSerialStatus.Sold;
            SaleId = saleId;
            SoldAt = DateTime.UtcNow;
            if (warrantyPeriodMonths > 0)
            {
                WarrantyExpiryDate = SoldAt.Value.AddMonths(warrantyPeriodMonths);
            }
            UpdatedAt = DateTime.UtcNow;
            return Result.Success();
        }

        public Result MarkAsReturned(string? notes = null)
        {
            Status = ProductSerialStatus.Returned;
            if (!string.IsNullOrWhiteSpace(notes))
            {
                Notes = string.IsNullOrEmpty(Notes) ? notes : $"{Notes} | {notes}";
            }
            UpdatedAt = DateTime.UtcNow;
            return Result.Success();
        }

        public Result ReturnToStock(string? notes = null)
        {
            Status = ProductSerialStatus.InStock;
            SaleId = null;
            SoldAt = null;
            WarrantyExpiryDate = null;
            if (!string.IsNullOrWhiteSpace(notes))
            {
                Notes = string.IsNullOrEmpty(Notes) ? notes : $"{Notes} | {notes}";
            }
            UpdatedAt = DateTime.UtcNow;
            return Result.Success();
        }

        public Result MarkAsDefective(string reason)
        {
            Status = ProductSerialStatus.Defective;
            Notes = string.IsNullOrEmpty(Notes) ? $"عيب صناعة: {reason}" : $"{Notes} | عيب صناعة: {reason}";
            UpdatedAt = DateTime.UtcNow;
            return Result.Success();
        }
    }
}
