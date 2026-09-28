using POS.Shared.Domain;
using System;
using System.Collections.Generic;
using System.Text;

namespace Inventory.Domain.Catalog.Products.Errors
{
    public static class MonyErrors
    {
        public static Error Negative =>
            new("Mony.Negative", "القيمة لا يمكن أن تكون سالبة.");

        public static Error CurrencyRequired =>
            new("Mony.CurrencyRequired", "العملة مطلوبة.");
    }
}
