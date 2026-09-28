using Inventory.Domain;
using Inventory.Domain.Catalog.Brands;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Brands.Commands.UpdateBrand
{
    internal sealed class UpdateBrandCommandHandler : ICommandHandler<UpdateBrandCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public UpdateBrandCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateBrandCommand request, CancellationToken cancellationToken)
        {
            var brand = await _unitOfWork.BrandRepository.GetByIdAsync(request.Id);
            if (brand is null)
                return Result.Failure(BrandErrors.NotFound(request.Id));

            string effectiveName = !string.IsNullOrWhiteSpace(request.Name)
                ? request.Name.Trim()
                : (!string.IsNullOrWhiteSpace(request.NameAr) && !string.IsNullOrWhiteSpace(request.NameEn))
                    ? $"{request.NameAr.Trim()} ({request.NameEn.Trim()})"
                    : !string.IsNullOrWhiteSpace(request.NameAr)
                        ? request.NameAr.Trim()
                        : request.NameEn?.Trim() ?? "";

            if (!string.IsNullOrWhiteSpace(effectiveName))
            {
                var updateResult = brand.Rename(effectiveName);
                if (updateResult.IsFailure)
                    return updateResult;
            }

            if (request.IsActive.HasValue)
            {
                if (request.IsActive.Value) brand.Activate();
                else brand.Deactivate();
            }

            _unitOfWork.BrandRepository.Update(brand);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
