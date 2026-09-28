using FluentValidation;

namespace Returns.Application.PurchaseReturns.Commands.CreatePurchaseReturn
{
    internal sealed class CreatePurchaseReturnCommandValidator : AbstractValidator<CreatePurchaseReturnCommand>
    {
        public CreatePurchaseReturnCommandValidator()
        {
            RuleFor(x => x.OriginalPurchaseId).NotEmpty().WithMessage("معرف فاتورة الشراء الأصلية مطلوب.");
            RuleFor(x => x.SupplierId).NotEmpty().WithMessage("معرف المورد مطلوب.");
            RuleFor(x => x.CreatedByUserId).NotEmpty().WithMessage("معرف المستخدم المنشئ مطلوب.");
            RuleFor(x => x.Items).NotEmpty().WithMessage("مرتجع الشراء يجب أن يحتوي على عنصر واحد على الأقل.");
        }
    }
}
