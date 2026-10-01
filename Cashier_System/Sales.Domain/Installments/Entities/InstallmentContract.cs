using POS.Shared.Domain;

namespace Sales.Domain.Installments.Entities
{
    public sealed class InstallmentContract : Entity
    {
        private readonly List<InstallmentSchedule> _schedules = new();

        public string ContractNumber { get; private set; } = default!;
        public Guid SaleId { get; private set; }
        public Guid CustomerId { get; private set; }

        // بيانات الضامن (Guarantor)
        public string GuarantorName { get; private set; } = default!;
        public string GuarantorPhone { get; private set; } = default!;
        public string? GuarantorNationalId { get; private set; }
        public string? GuarantorAddress { get; private set; }
        public string? GuarantorNotes { get; private set; } // رقم إيصال الأمانة أو الضمانات

        // البيانات المالية للتقسيط
        public decimal TotalCashAmount { get; private set; }       // إجمالي السعر النقدي
        public decimal DownPayment { get; private set; }           // المقدم المدفوع
        public decimal InterestPercentage { get; private set; }    // نسبة الفائدة / الربح المضافة
        public decimal InterestAmount { get; private set; }        // قيمة الفائدة
        public decimal TotalInstallmentAmount { get; private set; } // الإجمالي بالتقسيط (بعد خصم المقدم وإضافة الفائدة)
        public decimal MonthlyInstallmentAmount { get; private set; } // القسط الشهري
        public int NumberOfMonths { get; private set; }            // عدد الشهور
        public DateTime StartDate { get; private set; }            // تاريخ استحقاق أول قسط

        public InstallmentContractStatus Status { get; private set; }
        public string? Notes { get; private set; }
        public DateTime CreatedAt { get; private set; }
        public DateTime? UpdatedAt { get; private set; }

        public IReadOnlyList<InstallmentSchedule> Schedules => _schedules.AsReadOnly();

        public decimal TotalPaidAmount => _schedules.Sum(s => s.PaidAmount);
        public decimal RemainingBalance => Math.Max(0, TotalInstallmentAmount - TotalPaidAmount);

        private InstallmentContract() { } // EF Core

        private InstallmentContract(
            Guid id,
            string contractNumber,
            Guid saleId,
            Guid customerId,
            string guarantorName,
            string guarantorPhone,
            string? guarantorNationalId,
            string? guarantorAddress,
            string? guarantorNotes,
            decimal totalCashAmount,
            decimal downPayment,
            decimal interestPercentage,
            int numberOfMonths,
            DateTime startDate,
            string? notes = null) : base(id)
        {
            ContractNumber = contractNumber;
            SaleId = saleId;
            CustomerId = customerId;
            GuarantorName = guarantorName.Trim();
            GuarantorPhone = guarantorPhone.Trim();
            GuarantorNationalId = guarantorNationalId?.Trim();
            GuarantorAddress = guarantorAddress?.Trim();
            GuarantorNotes = guarantorNotes?.Trim();

            TotalCashAmount = totalCashAmount;
            DownPayment = downPayment;
            InterestPercentage = Math.Max(0, interestPercentage);
            NumberOfMonths = Math.Max(1, numberOfMonths);
            StartDate = startDate;

            var baseRemaining = Math.Max(0, totalCashAmount - downPayment);
            InterestAmount = Math.Round(baseRemaining * (InterestPercentage / 100m), 2);
            TotalInstallmentAmount = baseRemaining + InterestAmount;
            MonthlyInstallmentAmount = Math.Round(TotalInstallmentAmount / NumberOfMonths, 2);

            Status = InstallmentContractStatus.Active;
            Notes = notes?.Trim();
            CreatedAt = DateTime.UtcNow;

            GenerateSchedules();
        }

        public static Result<InstallmentContract> Create(
            string contractNumber,
            Guid saleId,
            Guid customerId,
            string guarantorName,
            string guarantorPhone,
            decimal totalCashAmount,
            decimal downPayment,
            decimal interestPercentage,
            int numberOfMonths,
            DateTime startDate,
            string? guarantorNationalId = null,
            string? guarantorAddress = null,
            string? guarantorNotes = null,
            string? notes = null)
        {
            if (string.IsNullOrWhiteSpace(contractNumber))
                return Result<InstallmentContract>.Failure(new Error("InstallmentContract.NumberRequired", "رقم عقد التقسيط مطلوب."));

            if (saleId == Guid.Empty)
                return Result<InstallmentContract>.Failure(new Error("InstallmentContract.SaleIdRequired", "معرف فاتورة البيع مطلوب."));

            if (customerId == Guid.Empty)
                return Result<InstallmentContract>.Failure(new Error("InstallmentContract.CustomerIdRequired", "يجب تحديد عميل مسجل لعقد التقسيط."));

            guarantorName = string.IsNullOrWhiteSpace(guarantorName) ? "بدون ضامن" : guarantorName.Trim();
            guarantorPhone = string.IsNullOrWhiteSpace(guarantorPhone) ? "-" : guarantorPhone.Trim();

            if (totalCashAmount <= 0)
                return Result<InstallmentContract>.Failure(new Error("InstallmentContract.InvalidTotal", "إجمالي قيمة الأجهزة يجب أن تكون أكبر من صفر."));

            if (numberOfMonths <= 0)
                numberOfMonths = 12;

            var contract = new InstallmentContract(
                Guid.NewGuid(),
                contractNumber.Trim(),
                saleId,
                customerId,
                guarantorName,
                guarantorPhone,
                guarantorNationalId,
                guarantorAddress,
                guarantorNotes,
                totalCashAmount,
                downPayment,
                interestPercentage,
                numberOfMonths,
                startDate,
                notes);

            return Result<InstallmentContract>.Success(contract);
        }

        private void GenerateSchedules()
        {
            _schedules.Clear();
            decimal accumulated = 0;

            for (int i = 1; i <= NumberOfMonths; i++)
            {
                var dueDate = StartDate.AddMonths(i - 1);
                decimal installmentAmount;

                if (i == NumberOfMonths)
                {
                    // القسط الأخير يضبط أي كسور تقريب
                    installmentAmount = TotalInstallmentAmount - accumulated;
                }
                else
                {
                    installmentAmount = MonthlyInstallmentAmount;
                    accumulated += installmentAmount;
                }

                var scheduleResult = InstallmentSchedule.Create(
                    Id,
                    i,
                    dueDate,
                    installmentAmount,
                    $"قسط شهر {dueDate:MMMM yyyy}");

                if (scheduleResult.IsSuccess)
                {
                    _schedules.Add(scheduleResult.Value!);
                }
            }
        }

        public Result PaySchedule(Guid scheduleId, decimal amount, string paymentMethod = "Cash", string? notes = null)
        {
            var schedule = _schedules.FirstOrDefault(s => s.Id == scheduleId);
            if (schedule == null)
                return Result.Failure(new Error("InstallmentContract.ScheduleNotFound", "القسط المطلوب غير موجود في هذا العقد."));

            var result = schedule.Pay(amount, paymentMethod, notes);
            if (result.IsFailure)
                return result;

            UpdatedAt = DateTime.UtcNow;

            // تحديث حالة العقد إذا تم سداد كافة الأقساط بالكامل
            if (_schedules.All(s => s.Status == InstallmentStatus.Paid))
            {
                Status = InstallmentContractStatus.Completed;
            }

            return Result.Success();
        }

        public void RefreshScheduleStatuses()
        {
            foreach (var schedule in _schedules)
            {
                schedule.CheckOverdue();
            }

            if (_schedules.Any(s => s.Status == InstallmentStatus.Overdue) && Status == InstallmentContractStatus.Active)
            {
                // إذا كان هناك قسط متأخر
            }
        }

        public Result Cancel(string reason)
        {
            if (Status == InstallmentContractStatus.Cancelled)
                return Result.Failure(new Error("InstallmentContract.AlreadyCancelled", "العقد ملغي بالفعل."));

            Status = InstallmentContractStatus.Cancelled;
            Notes = string.IsNullOrEmpty(Notes) ? $"إلغاء: {reason}" : $"{Notes} | إلغاء: {reason}";
            UpdatedAt = DateTime.UtcNow;
            return Result.Success();
        }
    }
}
