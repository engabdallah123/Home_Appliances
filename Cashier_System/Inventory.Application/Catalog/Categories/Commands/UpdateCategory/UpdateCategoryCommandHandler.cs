using Inventory.Domain;
using Inventory.Domain.Catalog.Categories;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Categories.Commands.UpdateCategory
{
    internal sealed class UpdateCategoryCommandHandler : ICommandHandler<UpdateCategoryCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public UpdateCategoryCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateCategoryCommand request, CancellationToken cancellationToken)
        {
            var category = await _unitOfWork.CategoryRepository.GetByIdAsync(request.Id);
            if (category is null)
                return Result.Failure(CategoryErrors.NotFound(request.Id));

            var updateResult = category.Update(request.NameAr, request.NameEn, request.ParentCategoryId);
            if (updateResult.IsFailure)
                return updateResult;

            _unitOfWork.CategoryRepository.Update(category);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
