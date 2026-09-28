using POS.Shared.Application.Messaging;

namespace Sales.Application.Sales.Queries.GetCustomerDebts
{
    public sealed record GetCustomerDebtsQuery(
        string? SearchTerm = null,
        Guid? CustomerId = null) : IQuery<IReadOnlyList<CustomerDebtResponse>>;
}
