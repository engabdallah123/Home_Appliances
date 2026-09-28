using FluentValidation;

namespace Purchases.Application.Purchases.Commands.CreatePurchase
{
    internal sealed class CreatePurchaseCommandValidator : AbstractValidator<CreatePurchaseCommand>
    {
        public CreatePurchaseCommandValidator()
        {
            RuleFor(x => x.InvoiceNumber).NotEmpty().WithMessage("رقم الفاتورة مطلوب.");
            RuleFor(x => x.SupplierId).NotEmpty().WithMessage("معرف المورد مطلوب.");
            RuleFor(x => x.CreatedByUserId).NotEmpty().WithMessage("معرف المستخدم المنشئ مطلوب.");
            RuleFor(x => x.Items).NotEmpty().WithMessage("فاتورة الشراء يجب أن تحتوي على عنصر واحد على الأقل.");
        }
    }
}
