using Inventory.Domain;
using Inventory.Domain.Stock.StockMovements;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Purchases.Domain;
using Purchases.Domain.Purchases;

namespace Purchases.Application.Purchases.Commands.ReceivePurchase
{
    internal sealed class ReceivePurchaseCommandHandler : ICommandHandler<ReceivePurchaseCommand>
    {
        private readonly IPurchasesUnitOfWork _purchasesUnitOfWork;
        private readonly IInventoryUnitOfWork _inventoryUnitOfWork;

        public ReceivePurchaseCommandHandler(
            IPurchasesUnitOfWork purchasesUnitOfWork,
            IInventoryUnitOfWork inventoryUnitOfWork)
        {
            _purchasesUnitOfWork = purchasesUnitOfWork;
            _inventoryUnitOfWork = inventoryUnitOfWork;
        }

        public async Task<Result> Handle(ReceivePurchaseCommand request, CancellationToken cancellationToken)
        {
            var purchase = await _purchasesUnitOfWork.PurchaseRepository.FindAsync(p => p.Id == request.PurchaseId, new[] { "Items" });
            if (purchase is null)
                return Result.Failure(PurchaseErrors.NotFound(request.PurchaseId));

            var receiveResult = purchase.Receive();
            if (receiveResult.IsFailure)
                return receiveResult;

            // زيادة المخزون وإنشاء حركة مخزونية لكل عنصر
            foreach (var item in purchase.Items)
            {
                var product = await _inventoryUnitOfWork.ProductRepository.GetByIdAsync(item.ProductId, cancellationToken);
                if (product is not null)
                {
                    product.AdjustStock(item.Quantity, allowNegativeStock: true);
                    _inventoryUnitOfWork.ProductRepository.Update(product);

                    var movementResult = StockMovement.Create(
                        item.ProductId,
                        item.Quantity,
                        StockMovementType.Purchase,
                        request.UserId,
                        reference: purchase.InvoiceNumber,
                        notes: $"استلام شراء - فاتورة {purchase.InvoiceNumber}");

                    if (movementResult.IsSuccess)
                    {
                        await _inventoryUnitOfWork.StockMovementRepository.AddAsync(movementResult.Value!);
                    }
                }
            }

            await _purchasesUnitOfWork.SaveChangesAsync(cancellationToken);
            await _inventoryUnitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
