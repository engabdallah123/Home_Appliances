using POS.Shared.Application.Messaging;

namespace Sales.Application.Customers.Queries.GetCustomers
{
    public sealed record GetCustomersQuery() : IQuery<IReadOnlyList<CustomerResponse>>;
}
