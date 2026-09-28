using POS.Shared.Application.Messaging;

namespace Sales.Application.Customers.Commands.CreateCustomer
{
    public sealed record CreateCustomerCommand(
        string Name,
        string Phone,
        string? Email = null,
        string? Address = null) : ICommand<Guid>;
}
