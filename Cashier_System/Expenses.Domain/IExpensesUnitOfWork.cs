using Expenses.Domain.Expenses.Entities;
using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;

namespace Expenses.Domain
{
    public interface IExpensesUnitOfWork : IUnitOfWork
    {
        IBaseRepository<Expense> ExpenseRepository { get; }
    }
}
