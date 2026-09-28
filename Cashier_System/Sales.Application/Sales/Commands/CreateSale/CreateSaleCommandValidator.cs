using FluentValidation;

namespace Sales.Application.Sales.Commands.CreateSale
{
    internal sealed class CreateSaleCommandValidator : AbstractValidator<CreateSaleCommand>
    {
        public CreateSaleCommandValidator()
        {
            RuleFor(x => x.CashierId).NotEmpty().WithMessage("معرف الكاشير مطلوب.");
            RuleFor(x => x.ShiftId).NotEmpty().WithMessage("معرف الشفت مطلوب.");
            RuleFor(x => x.Items).NotEmpty().WithMessage("فاتورة البيع يجب أن تحتوي على عنصر واحد على الأقل.");
        }
    }
}
