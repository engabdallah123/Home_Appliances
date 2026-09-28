using POS.Shared.Application.Messaging;
using Sales.Application.Installments.DTOs;

namespace Sales.Application.Installments.Queries.GetInstallmentContractById
{
    public sealed record GetInstallmentContractByIdQuery(Guid Id) : IQuery<InstallmentContractDto>;
}
