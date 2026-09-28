using POS.Shared.Application.Messaging;

namespace Returns.Application.SalesReturns.Queries.GetSalesReturns
{
    public sealed record GetSalesReturnsQuery(
        Guid? CashierId = null,
        Guid? ShiftId = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<SalesReturnResponse>>;
}
