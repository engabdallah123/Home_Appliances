using Sales.Domain.Promotions.Entities;

namespace Sales.Application.Promotions.DTOs
{
    public sealed record OfferItemDto(
        Guid Id,
        Guid ProductId,
        string ProductName,
        string? ProductBarcode,
        decimal Quantity,
        decimal OriginalUnitPrice);

    public sealed record OfferDto(
        Guid Id,
        string Title,
        string? Description,
        OfferType Type,
        string TypeText,
        decimal? DiscountPercentage,
        decimal? FixedDiscountAmount,
        decimal? BundlePrice,
        DateTime StartDate,
        DateTime EndDate,
        bool IsActive,
        bool IsCurrentlyValid,
        Guid? TargetProductId,
        string? TargetProductName,
        Guid? TargetCategoryId,
        string? TargetCategoryName,
        Guid? TargetBrandId,
        string? TargetBrandName,
        DateTime CreatedAt,
        List<OfferItemDto>? Items = null);

    public sealed record CreateOfferItemRequest(
        Guid ProductId,
        decimal Quantity = 1);
}
