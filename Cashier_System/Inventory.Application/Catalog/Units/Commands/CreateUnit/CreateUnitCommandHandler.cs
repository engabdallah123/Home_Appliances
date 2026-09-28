using Inventory.Domain;
using Inventory.Domain.Catalog.Units;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Units.Commands.CreateUnit
{
    internal sealed class CreateUnitCommandHandler : ICommandHandler<CreateUnitCommand, Guid>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public CreateUnitCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateUnitCommand request, CancellationToken cancellationToken)
        {
            var unitResult = Unit.Create(request.NameAr, request.NameEn, request.Symbol);
            if (unitResult.IsFailure)
                return Result<Guid>.Failure(unitResult.Error);

            var unit = unitResult.Value!;
            await _unitOfWork.UnitRepository.AddAsync(unit);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<Guid>.Success(unit.Id);
        }
    }
}
