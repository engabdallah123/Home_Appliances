namespace Sales.Domain.Sales.Entities
{
    public enum ReservationStatus
    {
        None = 0,                   // ليس حجزاً مؤجلاً
        Reserved = 1,               // بضاعة محجوزة في المخزن (جهاز عروسة)
        PartiallyDispatched = 2,    // تم تسليم جزء من البضاعة
        FullyDispatched = 3         // تم تسليم كافة البضاعة المحجوزة
    }
}
