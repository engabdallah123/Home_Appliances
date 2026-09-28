using Inventory.Domain.Catalog.Products.Errors;
using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Products.Entities
{
    public sealed class Sku : IEquatable<Sku>
    {
        public string Value { get; private set; } = default!;

        private Sku() { } // For EF Core materialization (Clean C# - no EF reference)

        private Sku(string value) => Value = value;

        public static Result<Sku> Create(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return Result<Sku>.Failure(SKuErrors.Empty);

            if (value.Trim().Length > 50)
                return Result<Sku>.Failure(SKuErrors.TooLong); 

            return Result<Sku>.Success(new Sku(value.Trim().ToUpperInvariant()));
        }

        public bool Equals(Sku? other) => other is not null && Value == other.Value;
        public override bool Equals(object? obj) => Equals(obj as Sku);
        public override int GetHashCode() => Value.GetHashCode();
        public override string ToString() => Value;
    }
}
