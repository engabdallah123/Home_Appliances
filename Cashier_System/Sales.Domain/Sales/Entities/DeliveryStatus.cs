namespace Sales.Domain.Sales.Entities
{
    public enum DeliveryStatus
    {
        None = 0,               // بدون شحن / استلام فوري
        Preparing = 1,          // قيد التجهيز بالمخزن
        OutForDelivery = 2,     // خرج مع سيارة النقل / المندوب
        Delivered = 3,          // تم التسليم للعميل
        Failed = 4              // تعذر التسليم
    }
}
