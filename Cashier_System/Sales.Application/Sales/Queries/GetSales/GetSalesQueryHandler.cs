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
                    s.ShiftId, s.SubTotal, s.DiscountAmount, s.TaxAmount, s.DeliveryFee, s.TotalAmount,
                    s.PaidAmount, s.ChangeAmount, s.PaymentMethod,
                    CASE s.Status 
                        WHEN 1 THEN 'Completed' WHEN 2 THEN 'Returned' WHEN 3 THEN 'Cancelled' WHEN 4 THEN 'PartialReturn' ELSE 'Completed' 
                    END AS Status,
                    s.Notes,
                    s.IsDelivery, s.RecipientName, s.RecipientPhone, s.DeliveryAddress, s.DeliveryFloor, s.DriverName, s.DeliveryStatus,
                    s.IsReserved, s.TargetDeliveryDate, s.ReservationStatus,
                    s.IsInstallment, s.InstallmentContractId
                FROM [Sales].[Sales] s
                LEFT JOIN [Identity].[AspNetUsers] u ON (s.CashierId = TRY_CAST(u.Id AS uniqueidentifier) OR CAST(s.CashierId AS nvarchar(450)) = u.Id)
                LEFT JOIN [Sales].[Customers] c ON s.CustomerId = c.Id
                WHERE 1 = 1
                """;

            DateTime? fromDate = request.FromDate.HasValue
                ? (request.FromDate.Value.Kind == DateTimeKind.Utc ? request.FromDate.Value : DateTime.SpecifyKind(request.FromDate.Value, DateTimeKind.Local).ToUniversalTime())
                : null;

            DateTime? toDate = request.ToDate.HasValue
                ? (request.ToDate.Value.TimeOfDay == TimeSpan.Zero
                    ? DateTime.SpecifyKind(request.ToDate.Value.Date.AddDays(1).AddTicks(-1), DateTimeKind.Local).ToUniversalTime()
                    : (request.ToDate.Value.Kind == DateTimeKind.Utc ? request.ToDate.Value : DateTime.SpecifyKind(request.ToDate.Value, DateTimeKind.Local).ToUniversalTime()))
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

            var salesList = (await connection.QueryAsync<SaleResponse>(sql, new
            {
                request.CashierId,
                request.ShiftId,
                request.CustomerId,
                FromDate = fromDate,
                ToDate = toDate,
                Offset = offset,
                request.PageSize
            })).ToList();

            if (salesList.Any())
            {
                var saleIds = salesList.Select(s => s.Id).ToList();
                var itemsSql = """
                    SELECT 
                        si.Id, si.SaleId, si.ProductId, p.NameAr AS ProductName, p.Barcode,
                        si.Quantity, si.UnitPrice, si.Discount, si.Tax,
                        (si.Quantity * si.UnitPrice - si.Discount + si.Tax) AS Total,
                        ISNULL(p.BaseUnit, 'قطعة') AS UnitName,
                        b.Name AS BrandName, p.ModelNumber, p.WarrantyPeriodMonths, p.MaintenanceAgent
                    FROM [Sales].[SaleItems] si
                    LEFT JOIN [Inventory].[Products] p ON si.ProductId = p.Id
                    LEFT JOIN [Inventory].[Brands] b ON p.BrandId = b.Id
                    WHERE si.SaleId IN @SaleIds
                    """;

                var rawItems = await connection.QueryAsync<dynamic>(itemsSql, new { SaleIds = saleIds });
                var groupedItems = rawItems.GroupBy(i => (Guid)i.SaleId)
                    .ToDictionary(
                        g => g.Key,
                        g => (IReadOnlyList<SaleItemResponse>)g.Select(r => new SaleItemResponse(
                            (Guid)r.Id,
                            (Guid)r.ProductId,
                            (string?)r.ProductName,
                            (string?)r.Barcode,
                            (decimal)r.Quantity,
                            (decimal)r.UnitPrice,
                            (decimal)r.Discount,
                            (decimal)r.Tax,
                            (decimal)r.Total,
                            (string?)r.UnitName,
                            null, null, null,
                            (string?)r.BrandName,
                            (string?)r.ModelNumber,
                            r.WarrantyPeriodMonths != null ? (int)r.WarrantyPeriodMonths : 0,
                            (string?)r.MaintenanceAgent
                        )).ToList());

                foreach (var sale in salesList)
                {
                    if (groupedItems.TryGetValue(sale.Id, out var items))
                    {
                        sale.Items = items;
                    }
                }
            }

            return Result<IReadOnlyList<SaleResponse>>.Success(salesList);
        }
    }
}
