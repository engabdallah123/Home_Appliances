using POS.Shared.Application.Messaging;
using Sales.Application.Installments.DTOs;
using Sales.Domain.Installments.Entities;

namespace Sales.Application.Installments.Queries.GetInstallmentContracts
{
    public sealed record GetInstallmentContractsQuery(
        Guid? CustomerId = null,
        InstallmentContractStatus? Status = null,
        string? SearchTerm = null) : IQuery<IReadOnlyList<InstallmentContractDto>>;
}
