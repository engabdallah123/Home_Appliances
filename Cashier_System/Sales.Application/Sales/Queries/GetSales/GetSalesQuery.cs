using POS.Shared.Application.Messaging;

namespace Sales.Application.Sales.Queries.GetSales
{
    public sealed record GetSalesQuery(
        Guid? CashierId = null,
        Guid? ShiftId = null,
        Guid? CustomerId = null,
        DateTime? FromDate = null,
        DateTime? ToDate = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<SaleResponse>>;
}
