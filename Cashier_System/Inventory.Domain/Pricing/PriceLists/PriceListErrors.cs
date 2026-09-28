using POS.Shared.Domain;

namespace Inventory.Domain.Pricing.PriceLists
{
    public static class PriceListErrors
    {
        public static Error NotFound(Guid id) =>
            new("PriceList.NotFound", $"قائمة الأسعار بالرقم '{id}' غير موجودة.");

        public static readonly Error NameRequired =
            new("PriceList.NameRequired", "اسم قائمة الأسعار مطلوب.");

        public static readonly Error DuplicateName =
            Error.Conflict("PriceList.DuplicateName", "يوجد بالفعل قائمة أسعار بنفس الاسم.");
    }
}
