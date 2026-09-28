using FluentValidation;

namespace Sales.Application.Sales.Commands.PaySaleInvoice;

internal sealed class PaySaleInvoiceCommandValidator : AbstractValidator<PaySaleInvoiceCommand>
{
    public PaySaleInvoiceCommandValidator()
    {
        RuleFor(x => x.SaleId).NotEmpty().WithMessage("معرف الفاتورة مطلوب.");
        RuleFor(x => x.Amount).GreaterThan(0).WithMessage("مبلغ السداد يجب أن يكون أكبر من صفر.");
    }
}
