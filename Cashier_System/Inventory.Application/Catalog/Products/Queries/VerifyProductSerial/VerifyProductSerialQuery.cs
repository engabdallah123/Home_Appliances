using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Queries.VerifyProductSerial
{
    public sealed record VerifyProductSerialQuery(
        string SerialNumber,
        Guid? ProductId = null) : IQuery<ProductSerialResponse>;
}
