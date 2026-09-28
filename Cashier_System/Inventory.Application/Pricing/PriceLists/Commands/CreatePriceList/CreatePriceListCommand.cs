using POS.Shared.Application.Messaging;

namespace Inventory.Application.Pricing.PriceLists.Commands.CreatePriceList
{
    public sealed record CreatePriceListCommand(
        string Name,
        string? Description = null,
        bool IsDefault = false) : ICommand<Guid>;
}
