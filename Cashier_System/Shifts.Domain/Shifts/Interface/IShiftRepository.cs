using Shifts.Domain.Shifts.Entities;

namespace Shifts.Domain.Shifts.Interface
{
    public interface IShiftRepository
    {
        Task<Shift?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
        Task<Shift?> GetActiveShiftByCashierIdAsync(Guid cashierId, CancellationToken cancellationToken = default);
        Task<bool> HasOpenShiftAsync(Guid cashierId, CancellationToken cancellationToken = default);
        Task AddAsync(Shift shift, CancellationToken cancellationToken = default);
        void Update(Shift shift);
    }
}
