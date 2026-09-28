using POS.Shared.Application.Messaging;

namespace Sales.Application.Promotions.Commands.DeleteOffer
{
    public sealed record DeleteOfferCommand(Guid Id) : ICommand;
}
