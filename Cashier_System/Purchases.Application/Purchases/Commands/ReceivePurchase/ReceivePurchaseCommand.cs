using POS.Shared.Application.Messaging;

namespace Purchases.Application.Purchases.Commands.ReceivePurchase
{
    public sealed record ReceivePurchaseCommand(Guid PurchaseId, Guid UserId) : ICommand;
}
