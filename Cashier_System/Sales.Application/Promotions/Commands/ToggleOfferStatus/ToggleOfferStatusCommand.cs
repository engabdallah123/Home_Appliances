using POS.Shared.Application.Messaging;

namespace Sales.Application.Promotions.Commands.ToggleOfferStatus
{
    public sealed record ToggleOfferStatusCommand(Guid Id) : ICommand;
}
