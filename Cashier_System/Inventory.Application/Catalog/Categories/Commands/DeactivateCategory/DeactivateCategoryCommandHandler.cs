using Inventory.Domain;
using Inventory.Domain.Catalog.Categories;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Categories.Commands.DeactivateCategory
{
    internal sealed class DeactivateCategoryCommandHandler : ICommandHandler<DeactivateCategoryCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public DeactivateCategoryCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(DeactivateCategoryCommand request, CancellationToken cancellationToken)
        {
            var category = await _unitOfWork.CategoryRepository.GetByIdAsync(request.Id);
            if (category is null)
                return Result.Failure(CategoryErrors.NotFound(request.Id));

            var result = category.Deactivate();
            if (result.IsFailure)
                return result;

            _unitOfWork.CategoryRepository.Update(category);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
