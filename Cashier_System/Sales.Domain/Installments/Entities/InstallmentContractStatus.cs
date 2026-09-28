namespace Sales.Domain.Installments.Entities
{
    public enum InstallmentContractStatus
    {
        Active = 1,     // عقد ساري وجاري سداد الأقساط
        Completed = 2,  // تم سداد جميع الأقساط بالكامل
        Defaulted = 3,  // متعثر في السداد
        Cancelled = 4   // ملغي / مرتجع
    }
}
