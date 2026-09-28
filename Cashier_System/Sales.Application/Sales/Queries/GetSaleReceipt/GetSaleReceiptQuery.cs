using POS.Shared.Application.Messaging;

namespace Sales.Application.Sales.Queries.GetSaleReceipt
{
    public sealed record GetSaleReceiptQuery(Guid SaleId) : IQuery<ReceiptResponse>;
}
