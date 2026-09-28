using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Shifts.Domain.Shifts;

namespace Shifts.Application.Shifts.Queries.GetCurrentShift
{
    internal sealed class GetCurrentShiftQueryHandler : IQueryHandler<GetCurrentShiftQuery, ShiftResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetCurrentShiftQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<ShiftResponse>> Handle(GetCurrentShiftQuery request, CancellationToken cancellationToken)
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
                WHERE s.CashierId = @CashierId AND s.Status = 1
                """;

            var shift = await connection.QuerySingleOrDefaultAsync<ShiftResponse>(sql, new { request.CashierId });

            if (shift is null)
                return Result<ShiftResponse>.Failure(ShiftErrors.NoOpenShiftFound);

            return Result<ShiftResponse>.Success(shift);
        }
    }
}
