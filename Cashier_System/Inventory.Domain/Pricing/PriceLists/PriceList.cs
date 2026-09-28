using POS.Shared.Domain;

namespace Inventory.Domain.Pricing.PriceLists
{
    public sealed class PriceList : Entity
    {
        public string Name { get; private set; } = default!;
        public string? Description { get; private set; }
        public bool IsDefault { get; private set; }
        public bool IsActive { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private PriceList() { } // EF Core

        private PriceList(Guid id, string name, string? description, bool isDefault)
            : base(id)
        {
            Name = name;
            Description = description;
            IsDefault = isDefault;
            IsActive = true;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<PriceList> Create(string name, string? description = null, bool isDefault = false)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result<PriceList>.Failure(PriceListErrors.NameRequired);

            var priceList = new PriceList(Guid.NewGuid(), name.Trim(), description?.Trim(), isDefault);
            return Result<PriceList>.Success(priceList);
        }

        public Result UpdateInfo(string name, string? description, bool isDefault)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(PriceListErrors.NameRequired);

            Name = name.Trim();
            Description = description?.Trim();
            IsDefault = isDefault;
            return Result.Success();
        }

        public Result Activate() { IsActive = true; return Result.Success(); }
        public Result Deactivate() { IsActive = false; return Result.Success(); }

        public Result Rename(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(PriceListErrors.NameRequired);

            Name = name.Trim();
            return Result.Success();
        }
    }
}
