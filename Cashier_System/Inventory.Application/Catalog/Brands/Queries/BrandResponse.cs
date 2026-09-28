namespace Inventory.Application.Catalog.Brands.Queries
{
    public sealed record BrandResponse
    {
        public Guid Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string? NameAr { get; init; }
        public string? NameEn { get; init; }
        public string? Description { get; init; }
        public string? OriginCountry { get; init; }
        public string? AgentContactNumber { get; init; }
        public bool IsActive { get; init; }
        public DateTime CreatedAt { get; init; }

        public BrandResponse() { }

        public BrandResponse(
            Guid id,
            string name,
            bool isActive,
            DateTime createdAt,
            string? nameAr = null,
            string? nameEn = null,
            string? description = null,
            string? originCountry = null,
            string? agentContactNumber = null)
        {
            Id = id;
            Name = name;
            IsActive = isActive;
            CreatedAt = createdAt;
            NameAr = nameAr ?? name;
            NameEn = nameEn ?? name;
            Description = description;
            OriginCountry = originCountry;
            AgentContactNumber = agentContactNumber;
        }
    }
}
