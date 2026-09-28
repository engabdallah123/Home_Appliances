using FluentValidation;

namespace Settings.Application.StoreSettings.Commands.UpdateSettings
{
    internal sealed class UpdateSettingsCommandValidator : AbstractValidator<UpdateSettingsCommand>
    {
        public UpdateSettingsCommandValidator()
        {
            RuleFor(x => x.StoreName).NotEmpty().WithMessage("اسم المتجر مطلوب.");
            RuleFor(x => x.Currency).NotEmpty().MaximumLength(5).WithMessage("العملة مطلوبة ولا تتجاوز 5 حروف.");
            RuleFor(x => x.TaxRate).InclusiveBetween(0, 100).WithMessage("نسبة الضريبة يجب أن تكون بين 0 و 100.");
        }
    }
}
