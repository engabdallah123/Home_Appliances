using FluentValidation;

namespace Shifts.Application.Shifts.Commands.OpenShift
{
    internal sealed class OpenShiftCommandValidator : AbstractValidator<OpenShiftCommand>
    {
        public OpenShiftCommandValidator()
        {
            RuleFor(x => x.CashierId).NotEmpty().WithMessage("معرف الكاشير مطلوب.");
            RuleFor(x => x.OpeningCash).GreaterThanOrEqualTo(0).WithMessage("المبلغ الافتتاحي لا يمكن أن يكون سالباً.");
        }
    }
}
