using Expenses.Domain;
using Expenses.Domain.Expenses.Entities;
using Expenses.Infrastructre.Database;
using POS.Shared.Domain;
using POS.Shared.Infrastructure.Database;

namespace Expenses.Infrastructre
{
    public class ExpensesUnitOfWork : IExpensesUnitOfWork
    {
        private readonly ExpensesDbContext _dbContext;

        public IBaseRepository<Expense> ExpenseRepository { get; private set; }

        public ExpensesUnitOfWork(ExpensesDbContext dbContext)
        {
            _dbContext = dbContext;
            ExpenseRepository = new BaseRepository<Expense>(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
