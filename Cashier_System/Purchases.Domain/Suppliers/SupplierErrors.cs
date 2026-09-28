using POS.Shared.Domain;

namespace Purchases.Domain.Suppliers
{
    public static class SupplierErrors
    {
        public static Error NotFound(Guid id) =>
            new("Supplier.NotFound", $"المورد بالرقم '{id}' غير موجود.");

        public static readonly Error NameRequired =
            new("Supplier.NameRequired", "اسم المورد مطلوب.");

        public static readonly Error PhoneRequired =
            new("Supplier.PhoneRequired", "رقم هاتف المورد مطلوب.");
    }
}
