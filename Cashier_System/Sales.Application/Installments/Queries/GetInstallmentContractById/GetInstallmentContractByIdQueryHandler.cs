using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Application.Installments.DTOs;

namespace Sales.Application.Installments.Queries.GetInstallmentContractById
{
    internal sealed class GetInstallmentContractByIdQueryHandler : IQueryHandler<GetInstallmentContractByIdQuery, InstallmentContractDto>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetInstallmentContractByIdQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<InstallmentContractDto>> Handle(GetInstallmentContractByIdQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var contractSql = """
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
                INNER JOIN [Sales].[Sales] s ON c.SaleId = s.Id
                INNER JOIN [Sales].[Customers] cust ON c.CustomerId = cust.Id
                OUTER APPLY (
                    SELECT SUM(PaidAmount) AS TotalPaid
                    FROM [Sales].[InstallmentSchedules]
                    WHERE ContractId = c.Id
                ) sched
                WHERE c.Id = @Id
                """;

            var contract = await connection.QueryFirstOrDefaultAsync<InstallmentContractDto>(contractSql, new { request.Id });
            if (contract == null)
            {
                return Result<InstallmentContractDto>.Failure(new Error("InstallmentContract.NotFound", "عقد التقسيط غير موجود."));
            }

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
                WHERE ContractId = @ContractId
                ORDER BY InstallmentNumber ASC
                """;

            var schedules = (await connection.QueryAsync<InstallmentScheduleDto>(schedulesSql, new { ContractId = request.Id })).ToList();

            var result = contract with { Schedules = schedules };
            return Result<InstallmentContractDto>.Success(result);
        }
    }
}
