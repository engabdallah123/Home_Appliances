using POS.Shared.Application.Messaging;

namespace Shifts.Application.Shifts.Queries.GetShiftSummary
{
    public sealed record GetShiftSummaryQuery(Guid ShiftId) : IQuery<ShiftSummaryResponse>;
}
