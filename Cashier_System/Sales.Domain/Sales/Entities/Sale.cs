using POS.Shared.Domain;
using POS.Shared.Domain.Events.Sales;

namespace Sales.Domain.Sales.Entities
{
    public sealed class Sale : Entity
    {
        private readonly List<SaleItem> _items = new();
        private readonly List<SalePayment> _payments = new();

        public string InvoiceNumber { get; private set; } = default!;
        public DateTime SaleDate { get; private set; }
        public Guid CashierId { get; private set; }
        public Guid? CustomerId { get; private set; }
        public Guid ShiftId { get; private set; }

        public decimal SubTotal { get; private set; }
        public decimal DiscountAmount { get; private set; }
        public decimal TaxAmount { get; private set; }
        public decimal DeliveryFee { get; private set; }
        public decimal TotalAmount { get; private set; }

        public decimal PaidAmount { get; private set; }
        public decimal ChangeAmount { get; private set; }
        public string PaymentMethod { get; private set; } = default!;
        public SaleStatus Status { get; private set; }
        public string? Notes { get; private set; }

        // Delivery & Shipping Information
        public bool IsDelivery { get; private set; }
        public string? RecipientName { get; private set; }
        public string? RecipientPhone { get; private set; }
        public string? DeliveryAddress { get; private set; }
        public string? DeliveryFloor { get; private set; }
        public string? DriverName { get; private set; }
        public DeliveryStatus DeliveryStatus { get; private set; } = DeliveryStatus.None;

        // Reservation & Layaway (جهاز العرائس / تسليم مؤجل)
        public bool IsReserved { get; private set; }
        public DateTime? TargetDeliveryDate { get; private set; }
        public ReservationStatus ReservationStatus { get; private set; } = ReservationStatus.None;

        // Installment Details
        public bool IsInstallment { get; private set; }
        public Guid? InstallmentContractId { get; private set; }

        public IReadOnlyList<SaleItem> Items => _items.AsReadOnly();
        public IReadOnlyList<SalePayment> Payments => _payments.AsReadOnly();

        private Sale() { } // EF Core

        private Sale(
            Guid id, string invoiceNumber, Guid cashierId, Guid shiftId,
            Guid? customerId, decimal discountAmount, decimal taxAmount,
            decimal paidAmount, string paymentMethod, string? notes,
            bool isDelivery = false, string? recipientName = null, string? recipientPhone = null,
            string? deliveryAddress = null, string? deliveryFloor = null, decimal deliveryFee = 0,
            string? driverName = null, bool isReserved = false, DateTime? targetDeliveryDate = null,
            bool isInstallment = false)
            : base(id)
        {
            InvoiceNumber = invoiceNumber;
            SaleDate = DateTime.UtcNow;
            CashierId = cashierId;
            ShiftId = shiftId;
            CustomerId = customerId;
            DiscountAmount = discountAmount;
            TaxAmount = taxAmount;
            DeliveryFee = deliveryFee;
            PaidAmount = paidAmount;
            PaymentMethod = paymentMethod;
            Status = SaleStatus.Completed;
            Notes = notes;

            IsDelivery = isDelivery;
            RecipientName = recipientName?.Trim();
            RecipientPhone = recipientPhone?.Trim();
            DeliveryAddress = deliveryAddress?.Trim();
            DeliveryFloor = deliveryFloor?.Trim();
            DriverName = driverName?.Trim();
            DeliveryStatus = isDelivery ? DeliveryStatus.Preparing : DeliveryStatus.None;

            IsReserved = isReserved;
            TargetDeliveryDate = targetDeliveryDate;
            ReservationStatus = isReserved ? ReservationStatus.Reserved : ReservationStatus.None;

            IsInstallment = isInstallment;
        }

        public static Result<Sale> Create(
            string invoiceNumber, Guid cashierId, Guid shiftId,
            Guid? customerId = null, decimal discountAmount = 0,
            decimal taxAmount = 0, decimal paidAmount = 0,
            string paymentMethod = "Cash", string? notes = null,
            bool isDelivery = false, string? recipientName = null, string? recipientPhone = null,
            string? deliveryAddress = null, string? deliveryFloor = null, decimal deliveryFee = 0,
            string? driverName = null, bool isReserved = false, DateTime? targetDeliveryDate = null,
            bool isInstallment = false)
        {
            if (string.IsNullOrWhiteSpace(invoiceNumber))
                return Result<Sale>.Failure(SaleErrors.InvoiceNumberRequired);

            if (cashierId == Guid.Empty)
                return Result<Sale>.Failure(SaleErrors.CashierIdRequired);

            if (shiftId == Guid.Empty)
                return Result<Sale>.Failure(SaleErrors.ShiftIdRequired);

            var sale = new Sale(
                Guid.NewGuid(), invoiceNumber.Trim(), cashierId, shiftId,
                customerId, discountAmount, taxAmount, paidAmount,
                paymentMethod.Trim(), notes?.Trim(),
                isDelivery, recipientName, recipientPhone,
                deliveryAddress, deliveryFloor, deliveryFee,
                driverName, isReserved, targetDeliveryDate,
                isInstallment);

            return Result<Sale>.Success(sale);
        }

        public Result AddItem(Guid productId, decimal quantity, decimal unitPrice, decimal discount = 0, decimal tax = 0, string? serialNumber = null)
        {
            var itemResult = SaleItem.Create(Id, productId, quantity, unitPrice, discount, tax, serialNumber);
            if (itemResult.IsFailure)
                return itemResult;

            _items.Add(itemResult.Value!);
            CalculateTotals();
            return Result.Success();
        }

        public Result Complete()
        {
            if (!_items.Any())
                return Result.Failure(SaleErrors.SaleHasNoItems);

            CalculateTotals();

            // إذا كان المبلغ المدفوع أقل من الإجمالي، يُسمح بذلك كـ آجل / قسط فقط إذا تم تحديد عميل، أو كانت طريقة الدفع آجل / تقسيط
            bool isCreditOrInstallment = PaymentMethod.Equals("Credit", StringComparison.OrdinalIgnoreCase) ||
                                         PaymentMethod.Equals("Installment", StringComparison.OrdinalIgnoreCase) ||
                                         IsInstallment;

            if (PaidAmount + 0.01m < TotalAmount && !isCreditOrInstallment && !CustomerId.HasValue)
                return Result.Failure(SaleErrors.CustomerRequiredForCredit);

            ChangeAmount = PaidAmount > TotalAmount ? PaidAmount - TotalAmount : 0;
            Status = SaleStatus.Completed;

            // تسجيل الدفعة الأولية إذا كانت الفاتورة مسددة كلياً أو جزئياً عند الإنشاء
            if (PaidAmount > 0 && !_payments.Any())
            {
                var initialPayment = SalePayment.Create(
                    Id,
                    Math.Min(PaidAmount, TotalAmount),
                    SaleDate,
                    PaymentMethod,
                    CashierId,
                    ShiftId,
                    IsInstallment ? "مقدم قسط عند البيع" : "دفعة أولية عند البيع");

                if (initialPayment.IsSuccess)
                {
                    _payments.Add(initialPayment.Value!);
                }
            }

            RaiseDomainEvent(new SaleCompletedIntegrationEvent(Id, ShiftId, TotalAmount, PaymentMethod));
            return Result.Success();
        }

        public Result<SalePayment> AddPayment(
            decimal amount,
            DateTime? paymentDate = null,
            string paymentMethod = "Cash",
            Guid? cashierId = null,
            Guid? shiftId = null,
            string? notes = null)
        {
            if (amount <= 0)
                return Result<SalePayment>.Failure(new Error("Sale.InvalidPaymentAmount", "مبلغ السداد يجب أن يكون أكبر من صفر."));

            var remaining = TotalAmount - PaidAmount;
            if (remaining <= 0.001m)
                return Result<SalePayment>.Failure(new Error("Sale.AlreadyFullyPaid", "الفاتورة مسددة بالكامل بالفعل."));

            if (amount > remaining)
            {
                amount = remaining;
            }

            PaidAmount += amount;
            ChangeAmount = PaidAmount > TotalAmount ? PaidAmount - TotalAmount : 0;

            var paymentResult = SalePayment.Create(
                Id,
                amount,
                paymentDate ?? DateTime.UtcNow,
                paymentMethod,
                cashierId ?? CashierId,
                shiftId ?? ShiftId,
                notes);

            if (paymentResult.IsFailure)
                return Result<SalePayment>.Failure(paymentResult.Error);

            var payment = paymentResult.Value!;
            _payments.Add(payment);

            return Result<SalePayment>.Success(payment);
        }

        public void AttachInstallmentContract(Guid contractId, decimal interestAmount = 0)
        {
            IsInstallment = true;
            InstallmentContractId = contractId;
            if (interestAmount > 0)
            {
                TotalAmount += interestAmount;
            }
        }

        public void UpdateDeliveryStatus(DeliveryStatus status, string? driverName = null)
        {
            DeliveryStatus = status;
            if (!string.IsNullOrWhiteSpace(driverName))
            {
                DriverName = driverName.Trim();
            }
        }

        public void UpdateReservationStatus(ReservationStatus status)
        {
            ReservationStatus = status;
            if (status == ReservationStatus.None || status == ReservationStatus.FullyDispatched)
            {
                IsReserved = false;
            }
        }

        public Result Cancel()
        {
            if (Status == SaleStatus.Cancelled)
                return Result.Failure(SaleErrors.AlreadyCancelled);

            Status = SaleStatus.Cancelled;
            RaiseDomainEvent(new SaleCancelledIntegrationEvent(Id, ShiftId, TotalAmount));
            return Result.Success();
        }

        private void CalculateTotals()
        {
            SubTotal = _items.Sum(i => i.Quantity * i.UnitPrice);
            TotalAmount = Math.Max(0, SubTotal - DiscountAmount + TaxAmount + DeliveryFee);
            ChangeAmount = PaidAmount > TotalAmount ? PaidAmount - TotalAmount : 0;
        }
    }
}
