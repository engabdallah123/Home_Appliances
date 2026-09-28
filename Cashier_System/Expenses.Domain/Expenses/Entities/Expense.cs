using POS.Shared.Domain;

namespace Expenses.Domain.Expenses.Entities
{
    public sealed class Expense : Entity
    {
        public string Title { get; private set; } = default!;
        public string? Description { get; private set; }
        public decimal Amount { get; private set; }
        public DateTime ExpenseDate { get; private set; }
        public Guid CreatedByUserId { get; private set; }
        public string? Notes { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private Expense() { } // EF Core

        private Expense(Guid id, string title, string? description, decimal amount, DateTime expenseDate, Guid createdByUserId, string? notes)
            : base(id)
        {
            Title = title;
            Description = description;
            Amount = amount;
            ExpenseDate = expenseDate;
            CreatedByUserId = createdByUserId;
            Notes = notes;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<Expense> Create(string title, decimal amount, Guid createdByUserId, string? description = null, DateTime? expenseDate = null, string? notes = null)
        {
            if (string.IsNullOrWhiteSpace(title))
                return Result<Expense>.Failure(ExpenseErrors.TitleRequired);

            if (amount <= 0)
                return Result<Expense>.Failure(ExpenseErrors.InvalidAmount);

            if (createdByUserId == Guid.Empty)
                return Result<Expense>.Failure(ExpenseErrors.CreatedByRequired);

            var expense = new Expense(
                Guid.NewGuid(), title.Trim(), description?.Trim(), amount,
                expenseDate ?? DateTime.UtcNow, createdByUserId, notes?.Trim());

            return Result<Expense>.Success(expense);
        }
    }
}
