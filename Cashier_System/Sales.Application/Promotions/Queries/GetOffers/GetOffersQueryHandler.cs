using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Application.Promotions.DTOs;

namespace Sales.Application.Promotions.Queries.GetOffers
{
    internal sealed class GetOffersQueryHandler : IQueryHandler<GetOffersQuery, IReadOnlyList<OfferDto>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetOffersQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<OfferDto>>> Handle(GetOffersQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    o.Id, o.Title, o.Description, o.Type,
                    CASE o.Type
                        WHEN 0 THEN N'خصم على صنف'
                        WHEN 1 THEN N'خصم على تصنيف'
                        WHEN 2 THEN N'خصم على ماركة'
                        WHEN 3 THEN N'عرض بكج مجمع'
                        ELSE N'غير معروف'
                    END AS TypeText,
                    o.DiscountPercentage, o.FixedDiscountAmount, o.BundlePrice,
                    o.StartDate, o.EndDate, o.IsActive,
                    CASE 
                        WHEN o.IsActive = 1 AND GETUTCDATE() >= o.StartDate AND GETUTCDATE() <= o.EndDate THEN CAST(1 AS BIT) 
                        ELSE CAST(0 AS BIT) 
                    END AS IsCurrentlyValid,
                    o.TargetProductId, p.NameAr AS TargetProductName,
                    o.TargetCategoryId, c.NameAr AS TargetCategoryName,
                    o.TargetBrandId, b.Name AS TargetBrandName,
                    o.CreatedAt
                FROM [Sales].[Offers] o
                LEFT JOIN [Inventory].[Products] p ON o.TargetProductId = p.Id
                LEFT JOIN [Inventory].[Categories] c ON o.TargetCategoryId = c.Id
                LEFT JOIN [Inventory].[Brands] b ON o.TargetBrandId = b.Id
                WHERE 1 = 1
                """;

            if (request.OnlyActive.HasValue)
            {
                sql += " AND o.IsActive = @OnlyActive";
            }

            if (request.Type.HasValue)
            {
                sql += " AND o.Type = @Type";
            }

            sql += " ORDER BY o.CreatedAt DESC";

            var offers = (await connection.QueryAsync<OfferDto>(sql, new
            {
                request.OnlyActive,
                Type = request.Type.HasValue ? (int)request.Type.Value : (int?)null
            })).ToList();

            // Load items for bundle packages
            var bundleOfferIds = offers.Where(o => o.Type == Domain.Promotions.Entities.OfferType.BundlePackage).Select(o => o.Id).ToList();
            if (bundleOfferIds.Any())
            {
                var itemsSql = """
                    SELECT 
                        oi.Id, oi.OfferId, oi.ProductId,
                        p.NameAr AS ProductName, p.Barcode AS ProductBarcode,
                        oi.Quantity, p.SellingPrice AS OriginalUnitPrice
                    FROM [Sales].[OfferItems] oi
                    INNER JOIN [Inventory].[Products] p ON oi.ProductId = p.Id
                    WHERE oi.OfferId IN @BundleOfferIds
                    """;

                var allItems = (await connection.QueryAsync<dynamic>(itemsSql, new { BundleOfferIds = bundleOfferIds })).ToList();

                for (int i = 0; i < offers.Count; i++)
                {
                    if (offers[i].Type == Domain.Promotions.Entities.OfferType.BundlePackage)
                    {
                        var offerId = offers[i].Id;
                        var items = allItems
                            .Where(x => (Guid)x.OfferId == offerId)
                            .Select(x => new OfferItemDto(
                                (Guid)x.Id,
                                (Guid)x.ProductId,
                                (string)x.ProductName,
                                (string)x.ProductBarcode,
                                (decimal)x.Quantity,
                                (decimal)x.OriginalUnitPrice))
                            .ToList();

                        offers[i] = offers[i] with { Items = items };
                    }
                }
            }

            return Result<IReadOnlyList<OfferDto>>.Success(offers);
        }
    }
}
