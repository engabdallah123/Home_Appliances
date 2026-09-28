using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Queries.GetProductByBarcode
{
    public sealed record GetProductByBarcodeQuery(string Barcode) : IQuery<ProductResponse>;
}
