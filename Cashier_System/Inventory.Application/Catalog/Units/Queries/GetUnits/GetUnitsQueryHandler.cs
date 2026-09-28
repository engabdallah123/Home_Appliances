using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Units.Queries.GetUnits
{
    internal sealed class GetUnitsQueryHandler : IQueryHandler<GetUnitsQuery, IReadOnlyList<UnitResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetUnitsQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<UnitResponse>>> Handle(GetUnitsQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT Id, NameAr, NameEn, Symbol
                FROM [Inventory].[Units]
                ORDER BY NameAr ASC
                """;

            var units = await connection.QueryAsync<UnitResponse>(sql);
            return Result<IReadOnlyList<UnitResponse>>.Success(units.ToList());
        }
    }
}
