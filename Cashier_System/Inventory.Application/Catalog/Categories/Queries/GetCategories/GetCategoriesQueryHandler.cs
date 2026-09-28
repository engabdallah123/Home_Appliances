using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Categories.Queries.GetCategories
{
    internal sealed class GetCategoriesQueryHandler : IQueryHandler<GetCategoriesQuery, IReadOnlyList<CategoryResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetCategoriesQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<CategoryResponse>>> Handle(GetCategoriesQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT Id, NameAr, NameEn, ParentCategoryId, IsActive, CreatedAt
                FROM [Inventory].[Categories]
                WHERE (@OnlyActive IS NULL OR IsActive = @OnlyActive)
                ORDER BY NameAr ASC
                """;

            var categories = await connection.QueryAsync<CategoryResponse>(sql, new { request.OnlyActive });
            return Result<IReadOnlyList<CategoryResponse>>.Success(categories.ToList());
        }
    }
}
