namespace Sales.Domain.Installments.Entities
{
    public enum InstallmentStatus
    {
        Pending = 0,        // قيد الانتظار / لم يستحق بعد
        PartiallyPaid = 1,  // مسدد جزئياً
        Paid = 2,           // مسدد بالكامل
        Overdue = 3         // متأخر عن موعد الاستحقاق
    }
}
