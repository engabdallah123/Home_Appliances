using POS.Shared.Domain.Abstractions;
using Shifts.Domain.Shifts.Interface;

namespace Shifts.Domain
{
    public interface IShiftsUnitOfWork : IUnitOfWork
    {
        IShiftRepository ShiftRepository { get; }
    }
}
