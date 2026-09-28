using Sales.Domain.Promotions.Entities;

namespace Sales.Application.Promotions.DTOs
{
    public sealed record OfferItemDto
    {
        public Guid Id { get; init; }
        public Guid ProductId { get; init; }
        public string ProductName { get; init; } = string.Empty;
        public string? ProductBarcode { get; init; }
        public decimal Quantity { get; init; }
        public decimal OriginalUnitPrice { get; init; }

        public OfferItemDto() { }

        public OfferItemDto(
            Guid id,
            Guid productId,
            string productName,
            string? productBarcode,
            decimal quantity,
            decimal originalUnitPrice)
        {
            Id = id;
            ProductId = productId;
            ProductName = productName;
            ProductBarcode = productBarcode;
            Quantity = quantity;
            OriginalUnitPrice = originalUnitPrice;
        }
    }

    public sealed record OfferDto
    {
        public Guid Id { get; init; }
        public string Title { get; init; } = string.Empty;
        public string? Description { get; init; }
        public OfferType Type { get; init; }
        public string TypeText { get; init; } = string.Empty;
        public decimal? DiscountPercentage { get; init; }
        public decimal? FixedDiscountAmount { get; init; }
        public decimal? BundlePrice { get; init; }
        public DateTime StartDate { get; init; }
        public DateTime EndDate { get; init; }
        public bool IsActive { get; init; }
        public bool IsCurrentlyValid { get; init; }
        public Guid? TargetProductId { get; init; }
        public string? TargetProductName { get; init; }
        public Guid? TargetCategoryId { get; init; }
        public string? TargetCategoryName { get; init; }
        public Guid? TargetBrandId { get; init; }
        public string? TargetBrandName { get; init; }
        public DateTime CreatedAt { get; init; }
        public List<OfferItemDto>? Items { get; init; }

        public OfferDto() { }

        public OfferDto(
            Guid id,
            string title,
            string? description,
            OfferType type,
            string typeText,
            decimal? discountPercentage,
            decimal? fixedDiscountAmount,
            decimal? bundlePrice,
            DateTime startDate,
            DateTime endDate,
            bool isActive,
            bool isCurrentlyValid,
            Guid? targetProductId,
            string? targetProductName,
            Guid? targetCategoryId,
            string? targetCategoryName,
            Guid? targetBrandId,
            string? targetBrandName,
            DateTime createdAt,
            List<OfferItemDto>? items = null)
        {
            Id = id;
            Title = title;
            Description = description;
            Type = type;
            TypeText = typeText;
            DiscountPercentage = discountPercentage;
            FixedDiscountAmount = fixedDiscountAmount;
            BundlePrice = bundlePrice;
            StartDate = startDate;
            EndDate = endDate;
            IsActive = isActive;
            IsCurrentlyValid = isCurrentlyValid;
            TargetProductId = targetProductId;
            TargetProductName = targetProductName;
            TargetCategoryId = targetCategoryId;
            TargetCategoryName = targetCategoryName;
            TargetBrandId = targetBrandId;
            TargetBrandName = targetBrandName;
            CreatedAt = createdAt;
            Items = items;
        }
    }

    public sealed record CreateOfferItemRequest(
        Guid ProductId,
        decimal Quantity = 1);
}
