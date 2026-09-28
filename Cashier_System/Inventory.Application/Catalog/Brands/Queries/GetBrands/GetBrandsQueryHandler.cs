using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Brands.Queries.GetBrands
{
    internal sealed class GetBrandsQueryHandler : IQueryHandler<GetBrandsQuery, IReadOnlyList<BrandResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetBrandsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<BrandResponse>>> Handle(GetBrandsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = "SELECT Id, Name, Name AS NameAr, Name AS NameEn, IsActive, CreatedAt FROM [Inventory].[Brands] WHERE 1 = 1";

            if (request.OnlyActive.HasValue && request.OnlyActive.Value)
            {
                sql += " AND IsActive = 1";
            }

            sql += " ORDER BY Name ASC";

            var brands = await connection.QueryAsync<BrandResponse>(sql);
            return Result<IReadOnlyList<BrandResponse>>.Success(brands.ToList());
        }
    }
}
