using POS.Shared.Application.Messaging;

namespace Shifts.Application.Shifts.Queries.GetShiftById
{
    public sealed record GetShiftByIdQuery(Guid Id) : IQuery<ShiftResponse>;
}
