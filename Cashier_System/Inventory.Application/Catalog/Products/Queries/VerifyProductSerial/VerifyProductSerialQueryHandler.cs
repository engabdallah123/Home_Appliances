using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Products.Queries.VerifyProductSerial
{
    internal sealed class VerifyProductSerialQueryHandler : IQueryHandler<VerifyProductSerialQuery, ProductSerialResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public VerifyProductSerialQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<ProductSerialResponse>> Handle(VerifyProductSerialQuery request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(request.SerialNumber))
                return Result<ProductSerialResponse>.Failure(new Error("ProductSerial.Empty", "الرقم التسلسلي فارغ."));

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
                WHERE ps.SerialNumber = @SerialNumber
                """;

            if (request.ProductId.HasValue && request.ProductId.Value != Guid.Empty)
            {
                sql += " AND ps.ProductId = @ProductId";
            }

            var serial = await connection.QueryFirstOrDefaultAsync<ProductSerialResponse>(sql, new
            {
                SerialNumber = request.SerialNumber.Trim(),
                request.ProductId
            });

            if (serial == null)
            {
                return Result<ProductSerialResponse>.Failure(new Error("ProductSerial.NotFound", $"الرقم التسلسلي '{request.SerialNumber}' غير مسجل في النظام."));
            }

            return Result<ProductSerialResponse>.Success(serial);
        }
    }
}
