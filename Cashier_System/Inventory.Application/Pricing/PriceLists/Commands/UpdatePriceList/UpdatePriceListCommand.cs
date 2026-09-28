using POS.Shared.Application.Messaging;

namespace Inventory.Application.Pricing.PriceLists.Commands.UpdatePriceList
{
    public sealed record UpdatePriceListCommand(
        Guid Id,
        string Name,
        string? Description,
        bool IsDefault) : ICommand;
}
