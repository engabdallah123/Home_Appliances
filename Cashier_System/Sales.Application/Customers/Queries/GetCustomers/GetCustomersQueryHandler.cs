using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Sales.Application.Customers.Queries.GetCustomers
{
    internal sealed class GetCustomersQueryHandler : IQueryHandler<GetCustomersQuery, IReadOnlyList<CustomerResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetCustomersQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<CustomerResponse>>> Handle(GetCustomersQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT Id, Name, Phone, Email, Address, LoyaltyPoints, Balance, IsActive, CreatedAt
                FROM [Sales].[Customers]
                ORDER BY Name
                """;

            var customers = await connection.QueryAsync<CustomerResponse>(sql);
            return Result<IReadOnlyList<CustomerResponse>>.Success(customers.ToList());
        }
    }
}
