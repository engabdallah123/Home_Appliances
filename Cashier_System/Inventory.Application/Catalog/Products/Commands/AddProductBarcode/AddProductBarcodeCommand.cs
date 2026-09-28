using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Commands.AddProductBarcode
{
    public sealed record AddProductBarcodeCommand(
        Guid ProductId,
        string Barcode,
        bool IsDefault = false) : ICommand<Guid>;
}
