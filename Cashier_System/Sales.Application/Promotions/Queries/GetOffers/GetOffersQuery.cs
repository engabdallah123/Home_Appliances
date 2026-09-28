using POS.Shared.Application.Messaging;
using Sales.Application.Promotions.DTOs;
using Sales.Domain.Promotions.Entities;

namespace Sales.Application.Promotions.Queries.GetOffers
{
    public sealed record GetOffersQuery(
        bool? OnlyActive = null,
        OfferType? Type = null) : IQuery<IReadOnlyList<OfferDto>>;
}
