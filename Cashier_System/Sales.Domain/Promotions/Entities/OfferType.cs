namespace Sales.Domain.Promotions.Entities
{
    public enum OfferType
    {
        ProductDiscount = 0,    // خصم على صنف محدد
        CategoryDiscount = 1,   // خصم على قسم / تصنيف
        BrandDiscount = 2,      // خصم على ماركة / علامة تجارية
        BundlePackage = 3       // بكج مجمع (عرض جهاز العروسة / طقم أجهزة)
    }
}
