using Inventory.Domain.Catalog.Products.Entities;

namespace Inventory.Application.Catalog.Products.Queries
{
    public sealed class ProductSerialResponse
    {
        public Guid Id { get; set; }
        public Guid ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string SerialNumber { get; set; } = string.Empty;
        public ProductSerialStatus Status { get; set; }
        public string StatusText { get; set; } = string.Empty;
        public Guid? PurchaseId { get; set; }
        public Guid? SaleId { get; set; }
        public DateTime? SoldAt { get; set; }
        public DateTime? WarrantyExpiryDate { get; set; }
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
