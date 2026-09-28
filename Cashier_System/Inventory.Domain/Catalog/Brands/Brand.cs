using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Brands
{
    public sealed class Brand : Entity
    {
        public string Name { get; private set; } = default!;
        public string? NameAr { get; private set; }
        public string? NameEn { get; private set; }
        public string? Description { get; private set; }
        public string? OriginCountry { get; private set; }
        public string? AgentContactNumber { get; private set; }
        public bool IsActive { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private Brand() { } // EF Core

        private Brand(
            Guid id,
            string name,
            string? nameAr = null,
            string? nameEn = null,
            string? description = null,
            string? originCountry = null,
            string? agentContactNumber = null)
            : base(id)
        {
            Name = name;
            NameAr = nameAr;
            NameEn = nameEn;
            Description = description;
            OriginCountry = originCountry;
            AgentContactNumber = agentContactNumber;
            IsActive = true;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<Brand> Create(
            string name,
            string? nameAr = null,
            string? nameEn = null,
            string? description = null,
            string? originCountry = null,
            string? agentContactNumber = null)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result<Brand>.Failure(BrandErrors.NameRequired);

            var brand = new Brand(
                Guid.NewGuid(),
                name.Trim(),
                nameAr?.Trim(),
                nameEn?.Trim(),
                description?.Trim(),
                originCountry?.Trim(),
                agentContactNumber?.Trim());

            return Result<Brand>.Success(brand);
        }

        public Result Rename(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(BrandErrors.NameRequired);

            Name = name.Trim();
            return Result.Success();
        }

        public Result Update(
            string name,
            string? nameAr = null,
            string? nameEn = null,
            string? description = null,
            string? originCountry = null,
            string? agentContactNumber = null)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(BrandErrors.NameRequired);

            Name = name.Trim();
            NameAr = nameAr?.Trim();
            NameEn = nameEn?.Trim();
            Description = description?.Trim();
            OriginCountry = originCountry?.Trim();
            AgentContactNumber = agentContactNumber?.Trim();

            return Result.Success();
        }

        public Result Activate() { IsActive = true; return Result.Success(); }
        public Result Deactivate() { IsActive = false; return Result.Success(); }
    }
}
