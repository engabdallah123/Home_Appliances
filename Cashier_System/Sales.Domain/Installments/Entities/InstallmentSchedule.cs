using POS.Shared.Domain;

namespace Sales.Domain.Installments.Entities
{
    public sealed class InstallmentSchedule : Entity
    {
        public Guid ContractId { get; private set; }
        public int InstallmentNumber { get; private set; }
        public DateTime DueDate { get; private set; }
        public decimal Amount { get; private set; }
        public decimal PaidAmount { get; private set; }
        public DateTime? PaidDate { get; private set; }
        public InstallmentStatus Status { get; private set; }
        public string? PaymentMethod { get; private set; }
        public string? Notes { get; private set; }

        public decimal RemainingAmount => Math.Max(0, Amount - PaidAmount);

        private InstallmentSchedule() { } // EF Core

        private InstallmentSchedule(
            Guid id,
            Guid contractId,
            int installmentNumber,
            DateTime dueDate,
            decimal amount,
            string? notes = null) : base(id)
        {
            ContractId = contractId;
            InstallmentNumber = installmentNumber;
            DueDate = dueDate;
            Amount = amount;
            PaidAmount = 0;
            Status = InstallmentStatus.Pending;
            Notes = notes;
        }

        public static Result<InstallmentSchedule> Create(
            Guid contractId,
            int installmentNumber,
            DateTime dueDate,
            decimal amount,
            string? notes = null)
        {
            if (contractId == Guid.Empty)
                return Result<InstallmentSchedule>.Failure(new Error("InstallmentSchedule.ContractIdRequired", "معرف عقد التقسيط مطلوب."));

            if (installmentNumber <= 0)
                return Result<InstallmentSchedule>.Failure(new Error("InstallmentSchedule.InvalidNumber", "رقم القسط يجب أن يكون 1 أو أكثر."));

            if (amount <= 0)
                return Result<InstallmentSchedule>.Failure(new Error("InstallmentSchedule.InvalidAmount", "قيمة القسط يجب أن تكون أكبر من صفر."));

            var schedule = new InstallmentSchedule(Guid.NewGuid(), contractId, installmentNumber, dueDate, amount, notes);
            return Result<InstallmentSchedule>.Success(schedule);
        }

        public Result Pay(decimal amount, string paymentMethod = "Cash", string? notes = null)
        {
            if (amount <= 0)
                return Result.Failure(new Error("InstallmentSchedule.InvalidPayment", "مبلغ السداد يجب أن يكون أكبر من صفر."));

            if (Status == InstallmentStatus.Paid)
                return Result.Failure(new Error("InstallmentSchedule.AlreadyPaid", "هذا القسط مسدد بالكامل بالفعل."));

            var remaining = RemainingAmount;
            var paymentToApply = Math.Min(amount, remaining);

            PaidAmount += paymentToApply;
            PaymentMethod = paymentMethod;
            PaidDate = DateTime.UtcNow;

            if (!string.IsNullOrWhiteSpace(notes))
            {
                Notes = string.IsNullOrEmpty(Notes) ? notes : $"{Notes} | {notes}";
            }

            if (PaidAmount >= Amount)
            {
                Status = InstallmentStatus.Paid;
            }
            else
            {
                Status = InstallmentStatus.PartiallyPaid;
            }

            return Result.Success();
        }

        public void CheckOverdue()
        {
            if (Status == InstallmentStatus.Pending && DateTime.UtcNow.Date > DueDate.Date)
            {
                Status = InstallmentStatus.Overdue;
            }
        }
    }
}
