using Inventory.Domain.Catalog.Products.Errors;
using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Products.Entities
{
    public sealed class Money : IEquatable<Money>
    {
        public decimal Amount { get; private set; }
        public string Currency { get; private set; } = default!;

        private Money() { } // For EF Core materialization (Clean C# - no EF reference)

        private Money(decimal amount, string currency)
        {
            Amount = amount;
            Currency = currency;
        }

        public static Result<Money> Create(decimal amount, string currency = "EGP")
        {
            if (amount < 0)
                return Result<Money>.Failure(MonyErrors.Negative);

            if (string.IsNullOrWhiteSpace(currency))
                return Result<Money>.Failure(MonyErrors.CurrencyRequired);

            return Result<Money>.Success(new Money(amount, currency.Trim().ToUpperInvariant()));
        }

        public bool Equals(Money? other) => other is not null && Amount == other.Amount && Currency == other.Currency;
        public override bool Equals(object? obj) => Equals(obj as Money);
        public override int GetHashCode() => HashCode.Combine(Amount, Currency);
    }
}
