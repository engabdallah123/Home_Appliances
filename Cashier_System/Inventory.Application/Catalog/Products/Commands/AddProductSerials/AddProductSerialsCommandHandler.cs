using Inventory.Domain;
using Inventory.Domain.Catalog.Products.Entities;
using Inventory.Domain.Catalog.Products.Errors;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Products.Commands.AddProductSerials
{
    internal sealed class AddProductSerialsCommandHandler : ICommandHandler<AddProductSerialsCommand, int>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public AddProductSerialsCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<int>> Handle(AddProductSerialsCommand request, CancellationToken cancellationToken)
        {
            var product = await _unitOfWork.ProductRepository.GetByIdAsync(request.ProductId, cancellationToken);
            if (product is null)
                return Result<int>.Failure(ProductErrors.NotFound(request.ProductId));

            if (request.SerialNumbers == null || !request.SerialNumbers.Any())
                return Result<int>.Failure(new Error("ProductSerial.EmptyList", "قائمة الأرقام التسلسلية فارغة."));

            int addedCount = 0;
            foreach (var rawSerial in request.SerialNumbers)
            {
                var cleanSerial = rawSerial?.Trim();
                if (string.IsNullOrWhiteSpace(cleanSerial))
                    continue;

                // Check if already registered
                var existing = await _unitOfWork.ProductSerialRepository.FindAsync(
                    s => s.ProductId == request.ProductId && s.SerialNumber == cleanSerial);

                if (existing != null)
                    continue;

                var serialResult = ProductSerial.Create(request.ProductId, cleanSerial, request.PurchaseId, request.Notes);
                if (serialResult.IsSuccess)
                {
                    await _unitOfWork.ProductSerialRepository.AddAsync(serialResult.Value!);
                    addedCount++;
                }
            }

            if (addedCount > 0)
            {
                await _unitOfWork.SaveChangesAsync(cancellationToken);
            }

            return Result<int>.Success(addedCount);
        }
    }
}
