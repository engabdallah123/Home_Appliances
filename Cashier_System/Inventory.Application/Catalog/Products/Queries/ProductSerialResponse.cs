using Inventory.Domain.Catalog.Products.Entities;

namespace Inventory.Application.Catalog.Products.Queries
{
    public sealed record ProductSerialResponse(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string SerialNumber,
        ProductSerialStatus Status,
        string StatusText,
        Guid? PurchaseId,
        Guid? SaleId,
        DateTime? SoldAt,
        DateTime? WarrantyExpiryDate,
        string? Notes,
        DateTime CreatedAt);
}
