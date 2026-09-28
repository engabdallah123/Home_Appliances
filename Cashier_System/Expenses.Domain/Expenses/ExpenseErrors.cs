using POS.Shared.Domain;

namespace Expenses.Domain.Expenses
{
    public static class ExpenseErrors
    {
        public static Error NotFound(Guid id) =>
            new("Expense.NotFound", $"المصروف بالرقم '{id}' غير موجود.");

        public static readonly Error TitleRequired =
            new("Expense.TitleRequired", "عنوان المصروف مطلوب.");

        public static readonly Error InvalidAmount =
            new("Expense.InvalidAmount", "مبلغ المصروف يجب أن يكون أكبر من صفر.");

        public static readonly Error CreatedByRequired =
            new("Expense.CreatedByRequired", "معرف المستخدم المنشئ مطلوب.");
    }
}
