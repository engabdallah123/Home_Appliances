using POS.Shared.Application.Messaging;

namespace Shifts.Application.Shifts.Queries.GetCurrentShift
{
    public sealed record GetCurrentShiftQuery(Guid CashierId) : IQuery<ShiftResponse>;
}
