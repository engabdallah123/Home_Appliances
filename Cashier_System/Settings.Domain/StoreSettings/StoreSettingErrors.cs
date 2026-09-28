using POS.Shared.Domain;

namespace Settings.Domain.StoreSettings
{
    public static class StoreSettingErrors
    {
        public static readonly Error StoreNameRequired =
            new("StoreSetting.StoreNameRequired", "اسم المتجر مطلوب.");

        public static readonly Error CurrencyRequired =
            new("StoreSetting.CurrencyRequired", "العملة مطلوبة.");

        public static readonly Error TaxRateInvalid =
            new("StoreSetting.TaxRateInvalid", "نسبة الضريبة يجب أن تكون بين 0 و 100.");

        public static readonly Error NotFound =
            new("StoreSetting.NotFound", "لم يتم العثور على إعدادات المتجر.");
    }
}
