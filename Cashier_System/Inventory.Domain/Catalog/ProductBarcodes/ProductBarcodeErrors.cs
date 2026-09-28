using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.ProductBarcodes
{
    public static class ProductBarcodeErrors
    {
        public static readonly Error Empty =
            new("ProductBarcode.Empty", "الباركود لا يمكن أن يكون فارغًا.");

        public static readonly Error TooLong =
            new("ProductBarcode.TooLong", "الباركود لا يمكن أن يتجاوز 64 حرفًا.");

        public static readonly Error DuplicateBarcode =
            Error.Conflict("ProductBarcode.Duplicate", "يوجد بالفعل باركود بنفس القيمة.");

        public static Error NotFound(Guid id) =>
            new("ProductBarcode.NotFound", $"الباركود بالرقم '{id}' غير موجود.");
    }
}
