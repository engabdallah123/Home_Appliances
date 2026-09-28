using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Stock.StockMovements.Queries.GetStockMovements
{
    internal sealed class GetStockMovementsQueryHandler : IQueryHandler<GetStockMovementsQuery, IReadOnlyList<StockMovementResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetStockMovementsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<StockMovementResponse>>> Handle(GetStockMovementsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    m.Id, m.ProductId, p.NameAr AS ProductName, p.Barcode,
                    m.Quantity,
                    CASE m.Type 
                        WHEN 1 THEN 'Sale' WHEN 2 THEN 'Purchase' WHEN 3 THEN 'Adjustment' WHEN 4 THEN 'SaleReturn' WHEN 5 THEN 'PurchaseReturn' WHEN 6 THEN 'Damage' WHEN 7 THEN 'Transfer' ELSE 'Other' 
                    END AS Type,
                    m.Reference, m.Notes, m.MovementDate,
                    m.UserId, u.FullName AS UserName
                FROM [Inventory].[StockMovements] m
                LEFT JOIN [Inventory].[Products] p ON m.ProductId = p.Id
                LEFT JOIN [Identity].[AspNetUsers] u ON m.UserId = CAST(u.Id AS uniqueidentifier)
                WHERE 1 = 1
                """;

            if (request.ProductId.HasValue)
                sql += " AND m.ProductId = @ProductId";

            if (request.FromDate.HasValue)
                sql += " AND m.MovementDate >= @FromDate";

            if (request.ToDate.HasValue)
                sql += " AND m.MovementDate <= @ToDate";

            sql += " ORDER BY m.MovementDate DESC OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var offset = (request.Page - 1) * request.PageSize;

            var movements = await connection.QueryAsync<StockMovementResponse>(sql, new
            {
                request.ProductId,
                request.FromDate,
                request.ToDate,
                Offset = offset,
                request.PageSize
            });

            return Result<IReadOnlyList<StockMovementResponse>>.Success(movements.ToList());
        }
    }
}
