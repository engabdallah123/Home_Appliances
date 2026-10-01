using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;
using Shifts.Domain;

namespace Sales.Application.Installments.Commands.PayInstallmentSchedule
{
    internal sealed class PayInstallmentScheduleCommandHandler : ICommandHandler<PayInstallmentScheduleCommand>
    {
        private readonly ISalesUnitOfWork _salesUnitOfWork;
        private readonly IShiftsUnitOfWork _shiftsUnitOfWork;

        public PayInstallmentScheduleCommandHandler(
            ISalesUnitOfWork salesUnitOfWork,
            IShiftsUnitOfWork shiftsUnitOfWork)
        {
            _salesUnitOfWork = salesUnitOfWork;
            _shiftsUnitOfWork = shiftsUnitOfWork;
        }

        public async Task<Result> Handle(PayInstallmentScheduleCommand request, CancellationToken cancellationToken)
        {
            if (request.Amount <= 0)
                return Result.Failure(new Error("InstallmentPayment.InvalidAmount", "مبلغ السداد يجب أن يكون أكبر من صفر."));

            var schedule = await _salesUnitOfWork.InstallmentScheduleRepository.GetByIdAsync(request.ScheduleId);
            if (schedule == null)
                return Result.Failure(new Error("InstallmentPayment.ScheduleNotFound", "القسط المطلوب غير موجود."));

            var contractId = request.ContractId != Guid.Empty ? request.ContractId : schedule.ContractId;
            if (schedule.ContractId != contractId)
                return Result.Failure(new Error("InstallmentPayment.ScheduleMismatch", "القسط لا ينتمي إلى هذا العقد."));

            var contract = await _salesUnitOfWork.InstallmentContractRepository.GetByIdAsync(contractId);
            if (contract == null)
                return Result.Failure(new Error("InstallmentPayment.ContractNotFound", "عقد التقسيط غير موجود."));

            var payScheduleResult = schedule.Pay(request.Amount, request.PaymentMethod, request.Notes);
            if (payScheduleResult.IsFailure)
                return payScheduleResult;

            _salesUnitOfWork.InstallmentScheduleRepository.Update(schedule);

            // إضافة الدفعة إلى الفاتورة لضبط مدفوعات البيع والخزينة
            var sale = await _salesUnitOfWork.SaleRepository.GetByIdAsync(contract.SaleId);
            if (sale != null)
            {
                sale.AddPayment(
                    request.Amount,
                    DateTime.UtcNow,
                    request.PaymentMethod,
                    request.CashierId,
                    request.ShiftId,
                    $"سداد قسط رقم {schedule.InstallmentNumber} من عقد {contract.ContractNumber}");

                _salesUnitOfWork.SaleRepository.Update(sale);
            }

            // تحديث إجماليات الشفت المفتوح إن وجد
            Guid? effectiveShiftId = request.ShiftId;
            if ((!effectiveShiftId.HasValue || effectiveShiftId.Value == Guid.Empty) && request.CashierId.HasValue && request.CashierId.Value != Guid.Empty)
            {
                var activeShift = await _shiftsUnitOfWork.ShiftRepository.GetActiveShiftByCashierIdAsync(request.CashierId.Value, cancellationToken);
                effectiveShiftId = activeShift?.Id;
            }

            if (effectiveShiftId.HasValue && effectiveShiftId.Value != Guid.Empty)
            {
                var shift = await _shiftsUnitOfWork.ShiftRepository.GetByIdAsync(effectiveShiftId.Value, cancellationToken);
                if (shift != null)
                {
                    shift.RecordDebtCollection(request.Amount, request.PaymentMethod);
                    _shiftsUnitOfWork.ShiftRepository.Update(shift);
                    await _shiftsUnitOfWork.SaveChangesAsync(cancellationToken);
                }
            }

            // فحص اكتمال كافة أقساط العقد حتى لو تم السداد قبل الموعد المحدد النهائي
            var allSchedules = (await _salesUnitOfWork.InstallmentScheduleRepository.GetAllAsync())
                .Where(s => s.ContractId == contract.Id)
                .ToList();

            decimal totalPaidSoFar = allSchedules.Sum(s => s.PaidAmount);
            bool allSchedulesPaid = allSchedules.All(s => s.Status == Domain.Installments.Entities.InstallmentStatus.Paid);
            bool totalContractPaid = (contract.TotalInstallmentAmount - totalPaidSoFar) <= 0.01m;

            if (allSchedulesPaid || totalContractPaid)
            {
                contract.MarkAsCompleted();
                _salesUnitOfWork.InstallmentContractRepository.Update(contract);
            }

            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
