using POS.Shared.Domain;
using System;
using System.Collections.Generic;
using System.Text;

namespace Inventory.Domain.Stock.Warehouses
{
    public static class WarehouseErrors
    {
        public static Error NotFound(Guid id) =>
            new("Warehouse.NotFound", $"المخزن بالرقم '{id}' غير موجود.");

        public static readonly Error DuplicateCode =
            Error.Conflict("Warehouse.DuplicateCode", "يوجد بالفعل مخزن بنفس الكود.");

        public static readonly Error NameRequired =
            new("Warehouse.NameRequired", "اسم المخزن مطلوب.");

        public static readonly Error CodeRequired =
            new("Warehouse.CodeRequired", "كود المخزن مطلوب.");
    }
}
