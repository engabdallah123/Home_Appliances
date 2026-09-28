using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Purchases.Application.Purchases.Queries.GetSupplierDebts
{
    internal sealed class GetSupplierDebtsQueryHandler : IQueryHandler<GetSupplierDebtsQuery, IReadOnlyList<SupplierDebtResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetSupplierDebtsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<SupplierDebtResponse>>> Handle(GetSupplierDebtsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    p.Id AS PurchaseId,
                    p.InvoiceNumber,
                    p.PurchaseDate,
                    p.SupplierId,
                    s.Name AS SupplierName,
                    s.Phone AS SupplierPhone,
                    p.TotalAmount,
                    p.PaidAmount,
                    p.RemainingAmount,
                    CASE p.Status WHEN 1 THEN 'Draft' WHEN 2 THEN 'Received' WHEN 3 THEN 'Cancelled' ELSE 'Draft' END AS Status
                FROM [Purchases].[Purchases] p
                LEFT JOIN [Purchases].[Suppliers] s ON p.SupplierId = s.Id
                WHERE p.RemainingAmount > 0
                  AND p.Status != 3
                """;

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
                sql += " AND (s.Name LIKE @Search OR s.Phone LIKE @Search OR p.InvoiceNumber LIKE @Search)";

            if (request.SupplierId.HasValue)
                sql += " AND p.SupplierId = @SupplierId";

            sql += " ORDER BY p.PurchaseDate DESC";

            var debts = await connection.QueryAsync<SupplierDebtResponse>(sql, new
            {
                Search = $"%{request.SearchTerm}%",
                request.SupplierId
            });

            return Result<IReadOnlyList<SupplierDebtResponse>>.Success(debts.ToList());
        }
    }
}
