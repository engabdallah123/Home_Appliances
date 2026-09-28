using Dapper;
using Inventory.Domain.Catalog.Products.Entities;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Products.Queries.GetProductSerials
{
    internal sealed class GetProductSerialsQueryHandler : IQueryHandler<GetProductSerialsQuery, IReadOnlyList<ProductSerialResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetProductSerialsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<ProductSerialResponse>>> Handle(GetProductSerialsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    ps.Id, ps.ProductId, p.NameAr AS ProductName,
                    ps.SerialNumber, ps.Status,
                    CASE ps.Status
                        WHEN 0 THEN N'في المخزن'
                        WHEN 1 THEN N'تم البيع'
                        WHEN 2 THEN N'مرتجع'
                        WHEN 3 THEN N'تالف / عيب صناعة'
                        ELSE N'غير معروف'
                    END AS StatusText,
                    ps.PurchaseId, ps.SaleId, ps.SoldAt, ps.WarrantyExpiryDate,
                    ps.Notes, ps.CreatedAt
                FROM [Inventory].[ProductSerials] ps
                INNER JOIN [Inventory].[Products] p ON ps.ProductId = p.Id
                WHERE ps.ProductId = @ProductId
                """;

            if (request.Status.HasValue)
            {
                sql += " AND ps.Status = @Status";
            }

            sql += " ORDER BY ps.CreatedAt DESC";

            var serials = await connection.QueryAsync<ProductSerialResponse>(sql, new
            {
                request.ProductId,
                Status = request.Status.HasValue ? (int)request.Status.Value : (int?)null
            });

            return Result<IReadOnlyList<ProductSerialResponse>>.Success(serials.ToList());
        }
    }
}
