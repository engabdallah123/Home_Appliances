using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Shifts.Domain;
using Shifts.Domain.Shifts;
using Shifts.Domain.Shifts.Entities;

namespace Shifts.Application.Shifts.Commands.OpenShift
{
    internal sealed class OpenShiftCommandHandler : ICommandHandler<OpenShiftCommand, Guid>
    {
        private readonly IShiftsUnitOfWork _unitOfWork;

        public OpenShiftCommandHandler(IShiftsUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(OpenShiftCommand request, CancellationToken cancellationToken)
        {
            var hasOpenShift = await _unitOfWork.ShiftRepository.HasOpenShiftAsync(request.CashierId, cancellationToken);
            if (hasOpenShift)
                return Result<Guid>.Failure(ShiftErrors.AlreadyHasOpenShift);

            var shiftResult = Shift.Open(request.CashierId, request.OpeningCash, request.Notes);
            if (shiftResult.IsFailure)
                return Result<Guid>.Failure(shiftResult.Error);

            var shift = shiftResult.Value!;
            await _unitOfWork.ShiftRepository.AddAsync(shift, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<Guid>.Success(shift.Id);
        }
    }
}
