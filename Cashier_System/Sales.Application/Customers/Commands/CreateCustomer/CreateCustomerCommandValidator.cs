using FluentValidation;

namespace Sales.Application.Customers.Commands.CreateCustomer
{
    internal sealed class CreateCustomerCommandValidator : AbstractValidator<CreateCustomerCommand>
    {
        public CreateCustomerCommandValidator()
        {
            RuleFor(x => x.Name).NotEmpty().WithMessage("اسم العميل مطلوب.");
            RuleFor(x => x.Phone).NotEmpty().WithMessage("رقم هاتف العميل مطلوب.");
        }
    }
}
