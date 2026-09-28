using POS.Shared.Application.Messaging;

namespace Inventory.Application.Pricing.PriceLists.Commands.DeletePriceList
{
    public sealed record DeletePriceListCommand(Guid Id) : ICommand;
}
