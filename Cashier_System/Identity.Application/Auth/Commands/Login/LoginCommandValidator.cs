using FluentValidation;

namespace Identity.Application.Auth.Commands.Login
{
    internal sealed class LoginCommandValidator : AbstractValidator<LoginCommand>
    {
        public LoginCommandValidator()
        {
            RuleFor(x => x.UserName).NotEmpty().WithMessage("اسم المستخدم مطلوب.");
            RuleFor(x => x.Password).NotEmpty().WithMessage("كلمة المرور مطلوبة.");
        }
    }
}
