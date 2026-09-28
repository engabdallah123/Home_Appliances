using FluentValidation;

namespace Purchases.Application.Suppliers.Commands.CreateSupplier
{
    internal sealed class CreateSupplierCommandValidator : AbstractValidator<CreateSupplierCommand>
    {
        public CreateSupplierCommandValidator()
        {
            RuleFor(x => x.Name).NotEmpty().WithMessage("اسم المورد مطلوب.");
            RuleFor(x => x.Phone).NotEmpty().WithMessage("رقم هاتف المورد مطلوب.");
        }
    }
}
