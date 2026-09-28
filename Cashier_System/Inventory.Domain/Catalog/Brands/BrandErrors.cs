using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Brands
{
    public static class BrandErrors
    {
        public static Error NotFound(Guid id) =>
            new("Brand.NotFound", $"العلامة التجارية بالرقم '{id}' غير موجودة.");

        public static readonly Error NameRequired =
            new("Brand.NameRequired", "اسم العلامة التجارية مطلوب.");

        public static readonly Error DuplicateName =
            Error.Conflict("Brand.DuplicateName", "يوجد بالفعل علامة تجارية بنفس الاسم.");
    }
}
