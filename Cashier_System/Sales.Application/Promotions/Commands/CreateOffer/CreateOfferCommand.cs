using POS.Shared.Application.Messaging;
using Sales.Application.Promotions.DTOs;
using Sales.Domain.Promotions.Entities;

namespace Sales.Application.Promotions.Commands.CreateOffer
{
    public sealed record CreateOfferCommand(
        string? Title = null,
        string? Description = null,
        OfferType Type = OfferType.BundlePackage,
        decimal? DiscountPercentage = null,
        decimal? FixedDiscountAmount = null,
        decimal? BundlePrice = null,
        DateTime StartDate = default,
        DateTime EndDate = default,
        Guid? TargetProductId = null,
        Guid? TargetCategoryId = null,
        Guid? TargetBrandId = null,
        List<CreateOfferItemRequest>? Items = null,
        string? TitleAr = null,
        string? TitleEn = null,
        int? OfferType = null,
        decimal? DiscountPercent = null,
        decimal? DiscountAmount = null,
        decimal? PackagePrice = null) : ICommand<Guid>
    {
        public string ResolvedTitle =>
            !string.IsNullOrWhiteSpace(Title) ? Title.Trim() :
            !string.IsNullOrWhiteSpace(TitleAr) ? TitleAr.Trim() :
            !string.IsNullOrWhiteSpace(TitleEn) ? TitleEn.Trim() : "عرض ترويجي";

        public OfferType ResolvedType =>
            OfferType.HasValue ? (OfferType)OfferType.Value : Type;

        public decimal? ResolvedDiscountPercentage =>
            DiscountPercentage ?? (DiscountPercent > 0 ? DiscountPercent : null);

        public decimal? ResolvedFixedDiscountAmount =>
            FixedDiscountAmount ?? (DiscountAmount > 0 ? DiscountAmount : null);

        public decimal? ResolvedBundlePrice =>
            BundlePrice ?? (PackagePrice > 0 ? PackagePrice : null);
    }
}
