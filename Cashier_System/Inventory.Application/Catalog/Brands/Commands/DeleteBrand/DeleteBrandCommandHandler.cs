using Inventory.Domain;
using Inventory.Domain.Catalog.Brands;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Brands.Commands.DeleteBrand
{
    internal sealed class DeleteBrandCommandHandler : ICommandHandler<DeleteBrandCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public DeleteBrandCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(DeleteBrandCommand request, CancellationToken cancellationToken)
        {
            var brand = await _unitOfWork.BrandRepository.GetByIdAsync(request.Id);
            if (brand is null)
                return Result.Failure(BrandErrors.NotFound(request.Id));

            _unitOfWork.BrandRepository.Delete(brand);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
