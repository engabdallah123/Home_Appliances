namespace Inventory.Application.Catalog.Products.Commands.ImportProductsFromExcel
{
    public sealed class ProductImportResultDto
    {
        public int TotalRows { get; set; }
        public int SuccessCount { get; set; }
        public int ErrorCount { get; set; }
        public List<ProductImportErrorDto> Errors { get; set; } = new();
    }

    public sealed class ProductImportErrorDto
    {
        public int RowNumber { get; set; }
        public string Barcode { get; set; } = string.Empty;
        public string ProductName { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
    }
}
