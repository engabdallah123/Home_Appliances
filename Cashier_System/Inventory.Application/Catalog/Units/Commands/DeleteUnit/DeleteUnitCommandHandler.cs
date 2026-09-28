using Inventory.Domain;
using Inventory.Domain.Catalog.Units;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Units.Commands.DeleteUnit
{
    internal sealed class DeleteUnitCommandHandler : ICommandHandler<DeleteUnitCommand>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public DeleteUnitCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(DeleteUnitCommand request, CancellationToken cancellationToken)
        {
            var unit = await _unitOfWork.UnitRepository.FindAsync(u => u.Id == request.Id);
            if (unit is null)
                return Result.Failure(UnitErrors.NotFound(request.Id));

            _unitOfWork.UnitRepository.Delete(unit);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
