using Inventory.Domain;
using Inventory.Domain.Catalog.Categories;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Categories.Commands.ActivateCategory
{
    internal sealed class ActivateCategoryCommandHandler : ICommandHandler<ActivateCategoryCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public ActivateCategoryCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(ActivateCategoryCommand request, CancellationToken cancellationToken)
        {
            var category = await _unitOfWork.CategoryRepository.GetByIdAsync(request.Id);
            if (category is null)
                return Result.Failure(CategoryErrors.NotFound(request.Id));

            var result = category.Activate();
            if (result.IsFailure)
                return result;

            _unitOfWork.CategoryRepository.Update(category);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
