using POS.Shared.Application.Messaging;

namespace Purchases.Application.Purchases.Commands.PayPurchaseInvoice;

public sealed record PayPurchaseInvoiceCommand(Guid PurchaseId, decimal Amount) : ICommand;
