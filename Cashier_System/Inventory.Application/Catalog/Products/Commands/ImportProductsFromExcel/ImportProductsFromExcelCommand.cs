using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Commands.ImportProductsFromExcel
{
    public sealed record ImportProductsFromExcelCommand(
        byte[] FileBytes,
        bool UpdateExisting = false) : ICommand<ProductImportResultDto>;
}
