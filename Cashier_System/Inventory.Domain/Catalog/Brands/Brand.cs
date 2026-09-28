using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Brands
{
    public sealed class Brand : Entity
    {
        public string Name { get; private set; } = default!;
        public bool IsActive { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private Brand() { } // EF Core

        private Brand(Guid id, string name)
            : base(id)
        {
            Name = name;
            IsActive = true;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<Brand> Create(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result<Brand>.Failure(BrandErrors.NameRequired);

            var brand = new Brand(Guid.NewGuid(), name.Trim());
            return Result<Brand>.Success(brand);
        }

        public Result Rename(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(BrandErrors.NameRequired);

            Name = name.Trim();
            return Result.Success();
        }

        public Result Activate() { IsActive = true; return Result.Success(); }
        public Result Deactivate() { IsActive = false; return Result.Success(); }
    }
}
