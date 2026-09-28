using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Returns.Application.PurchaseReturns.Queries.GetPurchaseReturns
{
    internal sealed class GetPurchaseReturnsQueryHandler : IQueryHandler<GetPurchaseReturnsQuery, IReadOnlyList<PurchaseReturnResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetPurchaseReturnsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<PurchaseReturnResponse>>> Handle(GetPurchaseReturnsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    pr.Id, pr.ReturnNumber, pr.OriginalPurchaseId,
                    pr.SupplierId, s.Name AS SupplierName,
                    pr.ReturnDate, pr.SubTotal, pr.TaxAmount, pr.TotalAmount,
                    pr.Reason, pr.Notes,
                    CASE pr.Status WHEN 1 THEN 'Completed' WHEN 2 THEN 'Cancelled' ELSE 'Completed' END AS Status
                FROM [Returns].[PurchaseReturns] pr
                LEFT JOIN [Purchases].[Suppliers] s ON pr.SupplierId = s.Id
                WHERE 1 = 1
                """;

            if (request.SupplierId.HasValue)
                sql += " AND pr.SupplierId = @SupplierId";

            sql += " ORDER BY pr.ReturnDate DESC OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var offset = (request.Page - 1) * request.PageSize;

            var returns = await connection.QueryAsync<PurchaseReturnResponse>(sql, new
            {
                request.SupplierId,
                Offset = offset,
                request.PageSize
            });

            return Result<IReadOnlyList<PurchaseReturnResponse>>.Success(returns.ToList());
        }
    }
}
