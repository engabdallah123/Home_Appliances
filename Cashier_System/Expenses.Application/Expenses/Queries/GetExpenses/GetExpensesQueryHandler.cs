using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Expenses.Application.Expenses.Queries.GetExpenses
{
    internal sealed class GetExpensesQueryHandler : IQueryHandler<GetExpensesQuery, IReadOnlyList<ExpenseResponse>>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetExpensesQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<IReadOnlyList<ExpenseResponse>>> Handle(GetExpensesQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            var sql = """
                SELECT 
                    e.Id, e.Title, e.Description, e.Amount, e.ExpenseDate,
                    e.CreatedByUserId, u.FullName AS CreatedByName,
                    e.Notes, e.CreatedAt
                FROM [Expenses].[Expenses] e
                LEFT JOIN [Identity].[AspNetUsers] u ON e.CreatedByUserId = CAST(u.Id AS uniqueidentifier)
                WHERE 1 = 1
                """;

            DateTime? fromDate = request.FromDate.HasValue
                ? (request.FromDate.Value.Kind == DateTimeKind.Utc ? request.FromDate.Value : DateTime.SpecifyKind(request.FromDate.Value, DateTimeKind.Local).ToUniversalTime())
                : null;

            DateTime? toDate = request.ToDate.HasValue
                ? (request.ToDate.Value.Kind == DateTimeKind.Utc ? request.ToDate.Value : DateTime.SpecifyKind(request.ToDate.Value, DateTimeKind.Local).ToUniversalTime())
                : null;

            if (fromDate.HasValue)
                sql += " AND e.ExpenseDate >= @FromDate";

            if (toDate.HasValue)
                sql += " AND e.ExpenseDate <= @ToDate";

            sql += " ORDER BY e.ExpenseDate DESC OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY";

            var offset = (request.Page - 1) * request.PageSize;

            var expenses = await connection.QueryAsync<ExpenseResponse>(sql, new
            {
                FromDate = fromDate,
                ToDate = toDate,
                Offset = offset,
                request.PageSize
            });

            return Result<IReadOnlyList<ExpenseResponse>>.Success(expenses.ToList());
        }
    }
}
