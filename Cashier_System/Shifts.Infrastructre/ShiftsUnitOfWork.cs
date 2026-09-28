using Shifts.Domain;
using Shifts.Domain.Shifts.Interface;
using Shifts.Infrastructre.Database;
using Shifts.Infrastructre.Repositories;

namespace Shifts.Infrastructre
{
    public class ShiftsUnitOfWork : IShiftsUnitOfWork
    {
        private readonly ShiftsDbContext _dbContext;

        public IShiftRepository ShiftRepository { get; private set; }

        public ShiftsUnitOfWork(ShiftsDbContext dbContext)
        {
            _dbContext = dbContext;
            ShiftRepository = new ShiftRepository(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
