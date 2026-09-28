using Inventory.Domain;
using Inventory.Domain.Catalog.Units;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Units.Commands.UpdateUnit
{
    internal sealed class UpdateUnitCommandHandler : ICommandHandler<UpdateUnitCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public UpdateUnitCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(UpdateUnitCommand request, CancellationToken cancellationToken)
        {
            var unit = await _unitOfWork.UnitRepository.GetByIdAsync(request.Id);
            if (unit is null)
                return Result.Failure(UnitErrors.NotFound(request.Id));

            var updateResult = unit.Update(request.NameAr, request.NameEn, request.Symbol);
            if (updateResult.IsFailure)
                return updateResult;

            _unitOfWork.UnitRepository.Update(unit);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
