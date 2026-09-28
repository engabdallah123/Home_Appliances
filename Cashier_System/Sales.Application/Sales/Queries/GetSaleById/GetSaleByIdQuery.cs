using POS.Shared.Application.Messaging;

namespace Sales.Application.Sales.Queries.GetSaleById
{
    public sealed record GetSaleByIdQuery(Guid Id) : IQuery<SaleDetailResponse>;
}
