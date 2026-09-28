namespace Inventory.Application.Catalog.Products.Queries
{
    public sealed class ProductResponse
    {
        public Guid Id { get; set; }
        public string Barcode { get; set; } = string.Empty;
        public string NameAr { get; set; } = string.Empty;
        public string NameEn { get; set; } = string.Empty;
        public string? Description { get; set; }
        public Guid CategoryId { get; set; }
        public string? CategoryName { get; set; }
        public Guid UnitId { get; set; }
        public string? UnitSymbol { get; set; }
        public Guid? SupplierId { get; set; }
        public string? SupplierName { get; set; }
        public decimal PurchasePrice { get; set; }
        public decimal SellingPrice { get; set; }
        public decimal WholesalePrice { get; set; }
        public decimal QuantityInStock { get; set; }
        public decimal ReorderLevel { get; set; }
        public decimal MaxStockLevel { get; set; }
        public bool IsWeighable { get; set; }
        public bool IsActive { get; set; }
        public bool TrackExpiry { get; set; }
        public decimal TaxRate { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string BaseUnit { get; set; } = "قطعة";
        public string? ParentUnit { get; set; } = "كرتونة";
        public int ConversionFactor { get; set; } = 1;
        public int ShelfLifeDays { get; set; } = 0;
        public int ExpiryAlertDays { get; set; } = 3;
        public Guid? BrandId { get; set; }
        public string? BrandName { get; set; }
        public string? ModelNumber { get; set; }
        public string? Color { get; set; }
        public int WarrantyPeriodMonths { get; set; } = 12;
        public string? MaintenanceAgent { get; set; }
        public bool HasSerialNumber { get; set; }

        public ProductResponse() { }
    }
}
