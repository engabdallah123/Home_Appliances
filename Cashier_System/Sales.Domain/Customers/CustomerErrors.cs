using POS.Shared.Domain;

namespace Sales.Domain.Customers
{
    public static class CustomerErrors
    {
        public static Error NotFound(Guid id) =>
            new("Customer.NotFound", $"العميل بالرقم '{id}' غير موجود.");

        public static readonly Error NameRequired =
            new("Customer.NameRequired", "اسم العميل مطلوب.");

        public static readonly Error PhoneRequired =
            new("Customer.PhoneRequired", "رقم هاتف العميل مطلوب.");
    }
}
