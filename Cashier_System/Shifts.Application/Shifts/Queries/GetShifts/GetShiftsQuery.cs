using POS.Shared.Application.Messaging;

namespace Shifts.Application.Shifts.Queries.GetShifts
{
    public sealed record GetShiftsQuery(
        Guid? CashierId = null,
        DateTime? FromDate = null,
        DateTime? ToDate = null,
        int Page = 1,
        int PageSize = 50) : IQuery<IReadOnlyList<ShiftResponse>>;
}
