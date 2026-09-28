using POS.Shared.Domain;
using System;
using System.Collections.Generic;
using System.Text;

namespace Inventory.Domain.Catalog.Products.Errors
{
    public static class SKuErrors
    {
        public static Error Empty =>
            new("Sku.Empty", "SKU لا يمكن أن يكون فارغًا.");

        public static Error TooLong =>
            new("Sku.TooLong", "SKU لا يمكن أن يتجاوز 50 حرفًا.");
    }
}
