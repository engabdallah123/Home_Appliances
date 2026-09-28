using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Sales.Application.Sales.Queries.GetSales
{
    internal sealed class GetSalesQueryHandler : IQueryHandler<GetSalesQuery, IReadOnlyList<SaleResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetSalesQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<SaleResponse>>> Handle(GetSalesQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    s.Id, s.InvoiceNumber, s.SaleDate, s.CashierId,
                    u.FullName AS CashierName, s.CustomerId, c.Name AS CustomerName,
                    s.ShiftId, s.SubTotal, s.DiscountAmount, s.TaxAmount, s.TotalAmount,
                    s.PaidAmount, s.ChangeAmount, s.PaymentMethod,
                    CASE s.Status 
                        WHEN 1 THEN 'Completed' WHEN 2 THEN 'Returned' WHEN 3 THEN 'Cancelled' WHEN 4 THEN 'PartialReturn' ELSE 'Completed' 
                    END AS Status,
                    s.Notes
                FROM [Sales].[Sales] s
                LEFT JOIN [Identity].[AspNetUsers] u ON s.CashierId = TRY_CAST(u.Id AS uniqueidentifier)
                LEFT JOIN [Sales].[Customers] c ON s.CustomerId = c.Id
                WHERE 1 = 1
                """;

            DateTime? fromDate = request.FromDate.HasValue
                ? (request.FromDate.Value.Kind == DateTimeKind.Utc ? request.FromDate.Value : DateTime.SpecifyKind(request.FromDate.Value, DateTimeKind.Local).ToUniversalTime())
                : null;

            DateTime? toDate = request.ToDate.HasValue
                ? (request.ToDate.Value.Kind == DateTimeKind.Utc ? request.ToDate.Value : DateTime.SpecifyKind(request.ToDate.Value, DateTimeKind.Local).ToUniversalTime())
                : null;

            if (request.CashierId.HasValue)
                sql += " AND s.CashierId = @CashierId";

            if (request.ShiftId.HasValue)
                sql += " AND s.ShiftId = @ShiftId";

            if (request.CustomerId.HasValue)
                sql += " AND s.CustomerId = @CustomerId";

            if (fromDate.HasValue)
                sql += " AND s.SaleDate >= @FromDate";

            if (toDate.HasValue)
                sql += " AND s.SaleDate <= @ToDate";

            sql += " ORDER BY s.SaleDate DESC OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var offset = (request.Page - 1) * request.PageSize;

            var sales = await connection.QueryAsync<SaleResponse>(sql, new
            {
                request.CashierId,
                request.ShiftId,
                request.CustomerId,
                FromDate = fromDate,
                ToDate = toDate,
                Offset = offset,
                request.PageSize
            });

            return Result<IReadOnlyList<SaleResponse>>.Success(sales.ToList());
        }
    }
}
