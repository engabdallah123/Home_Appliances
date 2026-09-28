using FluentValidation;

namespace Purchases.Application.Purchases.Commands.PayPurchaseInvoice;

internal sealed class PayPurchaseInvoiceCommandValidator : AbstractValidator<PayPurchaseInvoiceCommand>
{
    public PayPurchaseInvoiceCommandValidator()
    {
        RuleFor(x => x.PurchaseId).NotEmpty();
        RuleFor(x => x.Amount).GreaterThan(0).WithMessage("مبلغ السداد يجب أن يكون أكبر من صفر.");
    }
}
