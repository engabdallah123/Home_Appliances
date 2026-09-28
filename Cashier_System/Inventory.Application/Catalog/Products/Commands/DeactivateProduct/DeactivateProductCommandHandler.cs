using Inventory.Domain;
using Inventory.Domain.Catalog.Products.Errors;
using POS.Shared.Application.IService;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Products.Commands.DeactivateProduct
{
    internal sealed class DeactivateProductCommandHandler : ICommandHandler<DeactivateProductCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;
        private readonly ICacheService _cacheService;

        public DeactivateProductCommandHandler(
            IInventoryUnitOfWork unitOfWork,
            ICacheService cacheService)
        {
            _unitOfWork = unitOfWork;
            _cacheService = cacheService;
        }

        public async Task<Result> Handle(DeactivateProductCommand request, CancellationToken cancellationToken)
        {
            var product = await _unitOfWork.ProductRepository.GetByIdAsync(request.Id);
            if (product is null)
                return Result.Failure(ProductErrors.NotFound(request.Id));

            var result = product.Deactivate();
            if (result.IsFailure)
                return result;

            _unitOfWork.ProductRepository.Update(product);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            await _cacheService.RemoveByPrefixAsync("products_", cancellationToken);
            await _cacheService.RemoveAsync($"product_id_{request.Id}", cancellationToken);
            await _cacheService.RemoveAsync($"product_barcode_{product.Barcode}", cancellationToken);
            await _cacheService.RemoveByPrefixAsync("dashboard_", cancellationToken);

            return Result.Success();
        }
    }
}
