using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Shifts.Domain.Shifts;

namespace Shifts.Application.Shifts.Queries.GetShiftSummary
{
    internal sealed class GetShiftSummaryQueryHandler : IQueryHandler<GetShiftSummaryQuery, ShiftSummaryResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;

        public GetShiftSummaryQueryHandler(ISqlConnectionFactory sqlConnectionFactory)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
        }

        public async Task<Result<ShiftSummaryResponse>> Handle(GetShiftSummaryQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string sql = """
                SELECT 
                    s.Id AS ShiftId,
                    s.CashierId,
                    u.FullName AS CashierName,
                    s.OpenedAt,
                    s.ClosedAt,
                    CASE s.Status 
                        WHEN 1 THEN 'Open'
                        WHEN 2 THEN 'Closed'
                        WHEN 3 THEN 'Cancelled'
                        ELSE 'Unknown'
                    END AS Status,
                    s.OpeningCash,
                    s.TotalSales,
                    s.TotalCash,
                    s.TotalCard,
                    s.TotalWallet,
                    s.TotalCredit,
                    s.TotalDiscount,
                    s.TotalTax,
                    s.TotalInvoices,
                    s.TotalReturns,
                    s.SystemCash AS ExpectedCashInDrawer,
                    s.ClosingCash AS ActualClosingCash,
                    s.CashDifference
                FROM [Shifts].[Shifts] s
                LEFT JOIN [Identity].[AspNetUsers] u ON s.CashierId = CAST(u.Id AS uniqueidentifier)
                WHERE s.Id = @ShiftId
                """;

            var summary = await connection.QuerySingleOrDefaultAsync<ShiftSummaryResponse>(sql, new { request.ShiftId });

            if (summary is null)
                return Result<ShiftSummaryResponse>.Failure(ShiftErrors.NotFound(request.ShiftId));

            return Result<ShiftSummaryResponse>.Success(summary);
        }
    }
}
