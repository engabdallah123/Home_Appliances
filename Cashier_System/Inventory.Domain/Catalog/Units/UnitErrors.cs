using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Units
{
    public static class UnitErrors
    {
        public static Error NotFound(Guid id) =>
            new("Unit.NotFound", $"الوحدة بالرقم '{id}' غير موجودة.");

        public static readonly Error NameArRequired =
            new("Unit.NameArRequired", "اسم الوحدة بالعربية مطلوب.");

        public static readonly Error NameEnRequired =
            new("Unit.NameEnRequired", "اسم الوحدة بالإنجليزية مطلوب.");

        public static readonly Error SymbolRequired =
            new("Unit.SymbolRequired", "رمز الوحدة مطلوب.");
    }
}
