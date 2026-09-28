using POS.Shared.Domain;
using System;
using System.Collections.Generic;
using System.Text;

namespace Inventory.Domain.Catalog.Products.Errors
{
    public static class BarcodeErrors
    {
        public static Error Empty =>
            new("Barcode.Empty", "الباركود لا يمكن أن يكون فارغًا.");
        public static Error TooLong =>
            new("Barcode.TooLong", "الباركود لا يمكن أن يتجاوز 64 حرفًا.");
    }
}
