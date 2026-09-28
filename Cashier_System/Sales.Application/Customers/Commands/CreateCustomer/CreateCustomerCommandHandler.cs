using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;
using Sales.Domain.Customers.Entities;

namespace Sales.Application.Customers.Commands.CreateCustomer
{
    internal sealed class CreateCustomerCommandHandler : ICommandHandler<CreateCustomerCommand, Guid>
    {
        private readonly ISalesUnitOfWork _unitOfWork;

        public CreateCustomerCommandHandler(ISalesUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateCustomerCommand request, CancellationToken cancellationToken)
        {
            var customerResult = Customer.Create(request.Name, request.Phone, request.Email, request.Address);
            if (customerResult.IsFailure)
                return Result<Guid>.Failure(customerResult.Error);

            var customer = customerResult.Value!;
            await _unitOfWork.CustomerRepository.AddAsync(customer);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<Guid>.Success(customer.Id);
        }
    }
}
