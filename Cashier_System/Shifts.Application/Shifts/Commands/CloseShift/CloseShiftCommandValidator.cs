using FluentValidation;

namespace Shifts.Application.Shifts.Commands.CloseShift
{
    internal sealed class CloseShiftCommandValidator : AbstractValidator<CloseShiftCommand>
    {
        public CloseShiftCommandValidator()
        {
            RuleFor(x => x.ShiftId).NotEmpty().WithMessage("معرف الشفت مطلوب.");
            RuleFor(x => x.ActualClosingCash).GreaterThanOrEqualTo(0).WithMessage("مبلغ الإغلاق لا يمكن أن يكون سالباً.");
        }
    }
}
