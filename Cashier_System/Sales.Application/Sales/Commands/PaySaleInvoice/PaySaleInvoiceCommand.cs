using POS.Shared.Application.Messaging;

namespace Sales.Application.Sales.Commands.PaySaleInvoice;

public sealed record PaySaleInvoiceCommand(Guid SaleId, decimal Amount) : ICommand;
