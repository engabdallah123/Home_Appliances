using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Products.Commands.AddProductSerials
{
    public sealed record AddProductSerialsCommand(
        Guid ProductId,
        List<string> SerialNumbers,
        Guid? PurchaseId = null,
        string? Notes = null) : ICommand<int>;
}
