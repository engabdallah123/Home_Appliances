using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Sales.Application.Sales.Queries.GetCustomerDebts
{
    internal sealed class GetCustomerDebtsQueryHandler : IQueryHandler<GetCustomerDebtsQuery, IReadOnlyList<CustomerDebtResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetCustomerDebtsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<CustomerDebtResponse>>> Handle(GetCustomerDebtsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    s.Id AS SaleId,
                    s.InvoiceNumber,
                    s.SaleDate,
                    s.CustomerId,
                    c.Name AS CustomerName,
                    c.Phone AS CustomerPhone,
                    s.TotalAmount,
                    s.PaidAmount,
                    (s.TotalAmount - s.PaidAmount) AS RemainingAmount,
                    s.PaymentMethod,
                    CASE s.Status WHEN 1 THEN 'Completed' WHEN 2 THEN 'Cancelled' ELSE 'Completed' END AS Status
                FROM [Sales].[Sales] s
                LEFT JOIN [Sales].[Customers] c ON s.CustomerId = c.Id
                WHERE s.Status = 1
                  AND (s.TotalAmount - s.PaidAmount) > 0.001
                """;

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
                sql += " AND (c.Name LIKE @Search OR c.Phone LIKE @Search OR s.InvoiceNumber LIKE @Search)";

            if (request.CustomerId.HasValue)
                sql += " AND s.CustomerId = @CustomerId";

            sql += " ORDER BY s.SaleDate DESC";

            var debts = await connection.QueryAsync<CustomerDebtResponse>(sql, new
            {
                Search = $"%{request.SearchTerm}%",
                request.CustomerId
            });

            return Result<IReadOnlyList<CustomerDebtResponse>>.Success(debts.ToList());
        }
    }
}
