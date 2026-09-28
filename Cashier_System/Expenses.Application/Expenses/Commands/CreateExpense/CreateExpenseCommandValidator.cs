using FluentValidation;

namespace Expenses.Application.Expenses.Commands.CreateExpense
{
    internal sealed class CreateExpenseCommandValidator : AbstractValidator<CreateExpenseCommand>
    {
        public CreateExpenseCommandValidator()
        {
            RuleFor(x => x.Title).NotEmpty().WithMessage("عنوان المصروف مطلوب.");
            RuleFor(x => x.Amount).GreaterThan(0).WithMessage("مبلغ المصروف يجب أن يكون أكبر من صفر.");
            RuleFor(x => x.CreatedByUserId).NotEmpty().WithMessage("معرف المستخدم المنشئ مطلوب.");
        }
    }
}
