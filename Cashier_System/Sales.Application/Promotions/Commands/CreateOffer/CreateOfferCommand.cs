using POS.Shared.Application.Messaging;
using Sales.Application.Promotions.DTOs;
using Sales.Domain.Promotions.Entities;

namespace Sales.Application.Promotions.Commands.CreateOffer
{
    public sealed record CreateOfferCommand(
        string Title,
        string? Description,
        OfferType Type,
        decimal? DiscountPercentage,
        decimal? FixedDiscountAmount,
        decimal? BundlePrice,
        DateTime StartDate,
        DateTime EndDate,
        Guid? TargetProductId = null,
        Guid? TargetCategoryId = null,
        Guid? TargetBrandId = null,
        List<CreateOfferItemRequest>? Items = null) : ICommand<Guid>;
}
