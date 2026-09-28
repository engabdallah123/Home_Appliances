using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Purchases.Application.Suppliers.Queries.GetSuppliers
{
    internal sealed class GetSuppliersQueryHandler : IQueryHandler<GetSuppliersQuery, IReadOnlyList<SupplierResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetSuppliersQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<SupplierResponse>>> Handle(GetSuppliersQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT Id, Name, Phone, Email, Address, ContactPerson, IsActive
                FROM [Purchases].[Suppliers]
                ORDER BY Name
                """;

            var suppliers = await connection.QueryAsync<SupplierResponse>(sql);
            return Result<IReadOnlyList<SupplierResponse>>.Success(suppliers.ToList());
        }
    }
}
