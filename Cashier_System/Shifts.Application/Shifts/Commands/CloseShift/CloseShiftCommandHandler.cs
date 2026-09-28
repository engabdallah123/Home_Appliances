using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Shifts.Domain;
using Shifts.Domain.Shifts;

namespace Shifts.Application.Shifts.Commands.CloseShift
{
    internal sealed class CloseShiftCommandHandler : ICommandHandler<CloseShiftCommand>
    {
        private readonly IShiftsUnitOfWork _unitOfWork;

        public CloseShiftCommandHandler(IShiftsUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result> Handle(CloseShiftCommand request, CancellationToken cancellationToken)
        {
            var shift = await _unitOfWork.ShiftRepository.GetByIdAsync(request.ShiftId, cancellationToken);
            if (shift is null)
                return Result.Failure(ShiftErrors.NotFound(request.ShiftId));

            var closeResult = shift.Close(request.ActualClosingCash, request.ClosingNotes);
            if (closeResult.IsFailure)
                return closeResult;

            _unitOfWork.ShiftRepository.Update(shift);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
