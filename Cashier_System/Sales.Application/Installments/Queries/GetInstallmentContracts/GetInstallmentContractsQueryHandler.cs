using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Application.Installments.DTOs;

namespace Sales.Application.Installments.Queries.GetInstallmentContracts
{
    internal sealed class GetInstallmentContractsQueryHandler : IQueryHandler<GetInstallmentContractsQuery, IReadOnlyList<InstallmentContractDto>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetInstallmentContractsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<InstallmentContractDto>>> Handle(GetInstallmentContractsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    c.Id, c.ContractNumber, c.SaleId, s.InvoiceNumber,
                    c.CustomerId, cust.Name AS CustomerName, cust.Phone AS CustomerPhone,
                    c.GuarantorName, c.GuarantorPhone, c.GuarantorNationalId, c.GuarantorAddress, c.GuarantorNotes,
                    c.TotalCashAmount, c.DownPayment, c.InterestPercentage, c.InterestAmount,
                    c.TotalInstallmentAmount, c.MonthlyInstallmentAmount,
                    ISNULL(sched.TotalPaid, 0) AS TotalPaidAmount,
                    CASE 
                        WHEN (c.TotalInstallmentAmount - ISNULL(sched.TotalPaid, 0)) < 0 THEN 0 
                        ELSE (c.TotalInstallmentAmount - ISNULL(sched.TotalPaid, 0)) 
                    END AS RemainingBalance,
                    c.NumberOfMonths, c.StartDate, c.Status,
                    CASE c.Status
                        WHEN 1 THEN N'ساري'
                        WHEN 2 THEN N'مكتمل'
                        WHEN 3 THEN N'متعثر'
                        WHEN 4 THEN N'ملغي'
                        ELSE N'غير معروف'
                    END AS StatusText,
                    c.Notes, c.CreatedAt
                FROM [Sales].[InstallmentContracts] c
                LEFT JOIN [Sales].[Sales] s ON c.SaleId = s.Id
                LEFT JOIN [Sales].[Customers] cust ON c.CustomerId = cust.Id
                OUTER APPLY (
                    SELECT SUM(PaidAmount) AS TotalPaid
                    FROM [Sales].[InstallmentSchedules]
                    WHERE ContractId = c.Id
                ) sched
                WHERE 1 = 1
                """;

            if (request.CustomerId.HasValue)
            {
                sql += " AND c.CustomerId = @CustomerId";
            }

            if (request.Status.HasValue)
            {
                sql += " AND c.Status = @Status";
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                sql += " AND (c.ContractNumber LIKE @Search OR cust.Name LIKE @Search OR cust.Phone LIKE @Search OR c.GuarantorName LIKE @Search OR c.GuarantorPhone LIKE @Search)";
            }

            sql += " ORDER BY c.CreatedAt DESC";

            var contractList = (await connection.QueryAsync<InstallmentContractDto>(sql, new
            {
                request.CustomerId,
                Status = request.Status.HasValue ? (int)request.Status.Value : (int?)null,
                Search = $"%{request.SearchTerm}%"
            })).ToList();

            if (contractList.Any())
            {
                var contractIds = contractList.Select(c => c.Id).ToList();
                var schedulesSql = """
                    SELECT 
                        Id, ContractId, InstallmentNumber, DueDate, Amount, PaidAmount,
                        CASE WHEN (Amount - PaidAmount) < 0 THEN 0 ELSE (Amount - PaidAmount) END AS RemainingAmount,
                        PaidDate, Status,
                        CASE Status
                            WHEN 0 THEN N'قيد الانتظار'
                            WHEN 1 THEN N'مسدد جزئياً'
                            WHEN 2 THEN N'مسدد بالكامل'
                            WHEN 3 THEN N'متأخر'
                            ELSE N'غير معروف'
                        END AS StatusText,
                        PaymentMethod, Notes
                    FROM [Sales].[InstallmentSchedules]
                    WHERE ContractId IN @ContractIds
                    ORDER BY InstallmentNumber ASC
                    """;

                var schedules = await connection.QueryAsync<InstallmentScheduleDto>(schedulesSql, new { ContractIds = contractIds });
                var groupedSchedules = schedules.GroupBy(s => s.ContractId).ToDictionary(g => g.Key, g => g.ToList());

                for (int i = 0; i < contractList.Count; i++)
                {
                    if (groupedSchedules.TryGetValue(contractList[i].Id, out var schedList))
                    {
                        contractList[i].Schedules = schedList;
                    }
                }
            }

            return Result<IReadOnlyList<InstallmentContractDto>>.Success(contractList);
        }
    }
}
