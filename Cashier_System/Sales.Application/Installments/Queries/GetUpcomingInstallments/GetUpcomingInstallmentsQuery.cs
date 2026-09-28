using POS.Shared.Application.Messaging;
using Sales.Application.Installments.DTOs;

namespace Sales.Application.Installments.Queries.GetUpcomingInstallments
{
    public sealed record GetUpcomingInstallmentsQuery(int DaysAhead = 30) : IQuery<IReadOnlyList<UpcomingInstallmentAlertDto>>;
}
