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
            if (schedule == null || schedule.ContractId != request.ContractId)
                return Result.Failure(new Error("InstallmentPayment.ScheduleNotFound", "القسط المطلوب غير موجود."));

            var contract = await _salesUnitOfWork.InstallmentContractRepository.GetByIdAsync(request.ContractId);
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
            if (request.ShiftId.HasValue && request.ShiftId.Value != Guid.Empty)
            {
                var shift = await _shiftsUnitOfWork.ShiftRepository.GetByIdAsync(request.ShiftId.Value, cancellationToken);
                if (shift != null)
                {
                    shift.RecordDebtCollection(request.Amount, request.PaymentMethod);
                    _shiftsUnitOfWork.ShiftRepository.Update(shift);
                    await _shiftsUnitOfWork.SaveChangesAsync(cancellationToken);
                }
            }

            // فحص اكتمال كافة أقساط العقد
            var allSchedules = (await _salesUnitOfWork.InstallmentScheduleRepository.GetAllAsync())
                .Where(s => s.ContractId == contract.Id)
                .ToList();

            if (allSchedules.All(s => s.Status == Domain.Installments.Entities.InstallmentStatus.Paid))
            {
                // تم الانتهاء
            }

            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
