using POS.Shared.Domain;

namespace Shifts.Domain.Shifts
{
    public static class ShiftErrors
    {
        public static Error NotFound(Guid id) =>
            new("Shift.NotFound", $"الشفت بالرقم '{id}' غير موجود.");

        public static readonly Error CashierRequired =
            new("Shift.CashierRequired", "معرف الكاشير مطلوب.");

        public static readonly Error InvalidOpeningCash =
            new("Shift.InvalidOpeningCash", "المبلغ الافتتاحي لا يمكن أن يكون سالباً.");

        public static readonly Error InvalidClosingCash =
            new("Shift.InvalidClosingCash", "مبلغ الإغلاق لا يمكن أن يكون سالباً.");

        public static readonly Error AlreadyHasOpenShift =
            Error.Conflict("Shift.AlreadyHasOpenShift", "يوجد شفت مفتوح بالفعل لهذا الكاشير.");

        public static readonly Error NoOpenShiftFound =
            new("Shift.NoOpenShiftFound", "لا يوجد شفت مفتوح حالياً.");

        public static readonly Error NotOpen =
            new("Shift.NotOpen", "هذا الشفت مغلق أو ملغى.");
    }
}
