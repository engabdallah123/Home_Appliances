using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Application.Installments.DTOs;

namespace Sales.Application.Installments.Queries.GetUpcomingInstallments
{
    internal sealed class GetUpcomingInstallmentsQueryHandler : IQueryHandler<GetUpcomingInstallmentsQuery, IReadOnlyList<UpcomingInstallmentAlertDto>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetUpcomingInstallmentsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<UpcomingInstallmentAlertDto>>> Handle(GetUpcomingInstallmentsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var maxDate = DateTime.UtcNow.Date.AddDays(request.DaysAhead);

            var sql = """
                SELECT 
                    s.Id AS ScheduleId,
                    c.Id AS ContractId,
                    c.ContractNumber,
                    cust.Name AS CustomerName,
                    cust.Phone AS CustomerPhone,
                    c.GuarantorName,
                    c.GuarantorPhone,
                    s.InstallmentNumber,
                    s.DueDate,
                    s.Amount,
                    s.PaidAmount,
                    (s.Amount - s.PaidAmount) AS RemainingAmount,
                    CASE WHEN s.DueDate < CAST(GETUTCDATE() AS DATE) THEN 1 ELSE 0 END AS IsOverdue,
                    DATEDIFF(day, CAST(GETUTCDATE() AS DATE), s.DueDate) AS DaysOverdueOrRemaining
                FROM [Sales].[InstallmentSchedules] s
                INNER JOIN [Sales].[InstallmentContracts] c ON s.ContractId = c.Id
                INNER JOIN [Sales].[Customers] cust ON c.CustomerId = cust.Id
                WHERE s.Status IN (0, 1, 3) -- Pending, PartiallyPaid, Overdue
                  AND (s.DueDate <= @MaxDate OR s.DueDate < CAST(GETUTCDATE() AS DATE))
                  AND c.Status = 1 -- Active Contract
                ORDER BY s.DueDate ASC
                """;

            var alerts = await connection.QueryAsync<UpcomingInstallmentAlertDto>(sql, new { MaxDate = maxDate });
            return Result<IReadOnlyList<UpcomingInstallmentAlertDto>>.Success(alerts.ToList());
        }
    }
}
