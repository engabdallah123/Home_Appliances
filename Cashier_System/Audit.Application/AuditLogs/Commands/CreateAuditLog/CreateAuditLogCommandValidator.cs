using FluentValidation;

namespace Audit.Application.AuditLogs.Commands.CreateAuditLog
{
    internal sealed class CreateAuditLogCommandValidator : AbstractValidator<CreateAuditLogCommand>
    {
        public CreateAuditLogCommandValidator()
        {
            RuleFor(x => x.Action).NotEmpty().WithMessage("نوع الإجراء مطلوب.");
            RuleFor(x => x.EntityName).NotEmpty().WithMessage("اسم الكيان مطلوب.");
        }
    }
}
