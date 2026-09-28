using POS.Shared.Application.Messaging;

namespace Inventory.Application.Pricing.ProductPrices.Commands.SetProductPrice
{
    public sealed record SetProductPriceCommand(
        Guid ProductId,
        Guid PriceListId,
        decimal Price,
        string Currency = "EGP") : ICommand<Guid>;
}
