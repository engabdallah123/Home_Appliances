using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Shifts.Domain.Shifts;

namespace Shifts.Application.Shifts.Queries.GetShiftById
{
    internal sealed class GetShiftByIdQueryHandler : IQueryHandler<GetShiftByIdQuery, ShiftResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetShiftByIdQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<ShiftResponse>> Handle(GetShiftByIdQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT 
                    s.Id,
                    s.CashierId,
                    u.FullName AS CashierName,
                    s.OpenedAt,
                    s.ClosedAt,
                    s.OpeningCash,
                    s.ClosingCash,
                    s.SystemCash,
                    s.CashDifference,
                    CASE s.Status 
                        WHEN 1 THEN 'Open'
                        WHEN 2 THEN 'Closed'
                        WHEN 3 THEN 'Cancelled'
                        ELSE 'Unknown'
                    END AS Status,
                    s.TotalSales,
                    s.TotalCash,
                    s.TotalCard,
                    s.TotalWallet,
                    s.TotalCredit,
                    s.TotalDiscount,
                    s.TotalTax,
                    s.TotalInvoices,
                    s.TotalReturns,
                    s.Notes,
                    s.ClosingNotes
                FROM [Shifts].[Shifts] s
                LEFT JOIN [Identity].[AspNetUsers] u ON s.CashierId = CAST(u.Id AS uniqueidentifier)
                WHERE s.Id = @Id
                """;

            var shift = await connection.QuerySingleOrDefaultAsync<ShiftResponse>(sql, new { request.Id });

            if (shift is null)
                return Result<ShiftResponse>.Failure(ShiftErrors.NotFound(request.Id));

            return Result<ShiftResponse>.Success(shift);
        }
    }
}
