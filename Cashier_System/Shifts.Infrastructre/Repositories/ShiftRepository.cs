using Shifts.Domain.Shifts.Entities;
using Shifts.Domain.Shifts.Interface;
using Shifts.Infrastructre.Database;
using Microsoft.EntityFrameworkCore;

namespace Shifts.Infrastructre.Repositories
{
    public class ShiftRepository : IShiftRepository
    {
        private readonly ShiftsDbContext _context;

        public ShiftRepository(ShiftsDbContext context)
        {
            _context = context;
        }

        public async Task<Shift?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await _context.Shifts.FirstOrDefaultAsync(s => s.Id == id, cancellationToken);
        }

        public async Task<Shift?> GetActiveShiftByCashierIdAsync(Guid cashierId, CancellationToken cancellationToken = default)
        {
            return await _context.Shifts
                .FirstOrDefaultAsync(s => s.CashierId == cashierId && s.Status == ShiftStatus.Open, cancellationToken);
        }

        public async Task<bool> HasOpenShiftAsync(Guid cashierId, CancellationToken cancellationToken = default)
        {
            return await _context.Shifts
                .AnyAsync(s => s.CashierId == cashierId && s.Status == ShiftStatus.Open, cancellationToken);
        }

        public async Task AddAsync(Shift shift, CancellationToken cancellationToken = default)
        {
            await _context.Shifts.AddAsync(shift, cancellationToken);
        }

        public void Update(Shift shift)
        {
            _context.Shifts.Update(shift);
        }
    }
}
