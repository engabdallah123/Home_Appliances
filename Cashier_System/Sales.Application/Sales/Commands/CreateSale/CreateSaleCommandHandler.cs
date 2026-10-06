using Inventory.Domain;
using Inventory.Domain.Stock.StockMovements;
using POS.Shared.Application.IService;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;
using Sales.Domain.Sales;
using Sales.Domain.Sales.Entities;
using Settings.Domain;
using Shifts.Domain;

namespace Sales.Application.Sales.Commands.CreateSale
{
    internal sealed class CreateSaleCommandHandler : ICommandHandler<CreateSaleCommand, CreateSaleResult>
    {
        private readonly ISalesUnitOfWork _salesUnitOfWork;
        private readonly IInventoryUnitOfWork _inventoryUnitOfWork;
        private readonly IShiftsUnitOfWork _shiftsUnitOfWork;
        private readonly ISettingsUnitOfWork _settingsUnitOfWork;
        private readonly ICacheService _cacheService;

        public CreateSaleCommandHandler(
            ISalesUnitOfWork salesUnitOfWork,
            IInventoryUnitOfWork inventoryUnitOfWork,
            IShiftsUnitOfWork shiftsUnitOfWork,
            ISettingsUnitOfWork settingsUnitOfWork,
            ICacheService cacheService)
        {
            _salesUnitOfWork = salesUnitOfWork;
            _inventoryUnitOfWork = inventoryUnitOfWork;
            _shiftsUnitOfWork = shiftsUnitOfWork;
            _settingsUnitOfWork = settingsUnitOfWork;
            _cacheService = cacheService;
        }

        public async Task<Result<CreateSaleResult>> Handle(CreateSaleCommand request, CancellationToken cancellationToken)
        {
            // 1. التحقق من وجود شفت مفتوح للكاشير أو استخدام الشفت المفتوح حالياً
            Shifts.Domain.Shifts.Entities.Shift? shift = null;
            if (request.ShiftId != Guid.Empty)
            {
                shift = await _shiftsUnitOfWork.ShiftRepository.GetByIdAsync(request.ShiftId, cancellationToken);
            }

            if (shift is null || shift.Status != Shifts.Domain.Shifts.Entities.ShiftStatus.Open)
            {
                var cashierId = request.CashierId != Guid.Empty ? request.CashierId : Guid.Parse("2bc4e49b-fe29-4c7b-9eed-649de1c32cef");
                shift = await _shiftsUnitOfWork.ShiftRepository.GetActiveShiftByCashierIdAsync(cashierId, cancellationToken);

                if (shift is null || shift.Status != Shifts.Domain.Shifts.Entities.ShiftStatus.Open)
                {
                    // فتح شفت افتراضي تلقائياً لتسجيل المبيعات فوراً دون تعطيل
                    var newShiftRes = Shifts.Domain.Shifts.Entities.Shift.Open(cashierId, 0, "وردية مبيعات افتراضية للنظام والموبايل");
                    if (newShiftRes.IsSuccess)
                    {
                        shift = newShiftRes.Value;
                        await _shiftsUnitOfWork.ShiftRepository.AddAsync(shift, cancellationToken);
                        await _shiftsUnitOfWork.SaveChangesAsync(cancellationToken);
                    }
                    else
                    {
                        return Result<CreateSaleResult>.Failure(SaleErrors.NoOpenShiftAvailable);
                    }
                }
            }

            // 2. فحص إعدادات التنسيق وحظر المخزون السالب
            var settings = (await _settingsUnitOfWork.StoreSettingRepository.GetAllAsync()).FirstOrDefault();
            var allowNegativeStock = (settings?.AllowNegativeStock ?? false) || request.BypassStockCheck;

            // 3. التحقق من توفر رصيد المخزون لكل عنصر
            foreach (var itemReq in request.Items)
            {
                var product = await _inventoryUnitOfWork.ProductRepository.GetByIdAsync(itemReq.ProductId, cancellationToken);
                if (product is null)
                    return Result<CreateSaleResult>.Failure(new Error("Product.NotFound", $"المنتج '{itemReq.ProductId}' غير موجود."));

                if (!allowNegativeStock && product.QuantityInStock < itemReq.Quantity)
                    return Result<CreateSaleResult>.Failure(new Error("Stock.Insufficient", $"الكمية المتاحة من '{product.NameAr}' هي {product.QuantityInStock} فقط."));
            }

            // 4. إنشاء الفاتورة
            int orderNumber = shift.TotalInvoices + 1;
            var invoiceNumber = !string.IsNullOrWhiteSpace(request.CustomInvoiceNumber)
                ? request.CustomInvoiceNumber.Trim()
                : $"INV-{DateTime.UtcNow:yyyyMMddHHmmss}-{orderNumber:D3}";

            var saleResult = Sale.Create(
                invoiceNumber, shift.CashierId, shift.Id,
                request.CustomerId, request.DiscountAmount, request.TaxAmount,
                request.PaidAmount, request.PaymentMethod, request.Notes,
                request.IsDelivery, request.RecipientName, request.RecipientPhone,
                request.DeliveryAddress, request.DeliveryFloor, request.DeliveryFee,
                request.DriverName, request.IsReserved, request.TargetDeliveryDate,
                request.IsInstallment);

            if (saleResult.IsFailure)
                return Result<CreateSaleResult>.Failure(saleResult.Error);

            var sale = saleResult.Value!;

            foreach (var itemReq in request.Items)
            {
                var itemResult = sale.AddItem(itemReq.ProductId, itemReq.Quantity, itemReq.UnitPrice, itemReq.Discount, itemReq.Tax, itemReq.SerialNumber);
                if (itemResult.IsFailure)
                    return Result<CreateSaleResult>.Failure(itemResult.Error);
            }

            var completeResult = sale.Complete();
            if (completeResult.IsFailure)
                return Result<CreateSaleResult>.Failure(completeResult.Error);

            if (request.IsInstallment || request.PaymentMethod == "Installment")
            {
                Guid customerId = request.CustomerId ?? Guid.Empty;
                if (customerId == Guid.Empty)
                {
                    var custName = !string.IsNullOrWhiteSpace(request.RecipientName)
                        ? request.RecipientName.Trim()
                        : "عميل تقسيط";
                    var custPhone = !string.IsNullOrWhiteSpace(request.RecipientPhone)
                        ? request.RecipientPhone.Trim()
                        : "-";

                    var existingCustomers = await _salesUnitOfWork.CustomerRepository.GetAllAsync();
                    var matchedCust = existingCustomers.FirstOrDefault(c =>
                        (!string.IsNullOrWhiteSpace(c.Phone) && custPhone != "-" && c.Phone.Trim() == custPhone) ||
                        c.Name.Trim().Equals(custName, StringComparison.OrdinalIgnoreCase));

                    if (matchedCust != null)
                    {
                        customerId = matchedCust.Id;
                    }
                    else
                    {
                        var newCustRes = global::Sales.Domain.Customers.Entities.Customer.Create(custName, custPhone, request.DeliveryAddress);
                        if (newCustRes.IsSuccess)
                        {
                            await _salesUnitOfWork.CustomerRepository.AddAsync(newCustRes.Value!);
                            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);
                            customerId = newCustRes.Value!.Id;
                        }
                    }
                }

                if (customerId != Guid.Empty)
                {
                    var contractNumber = $"INST-{DateTime.UtcNow:yyyyMMdd}-{orderNumber:D3}";
                    var contractResult = global::Sales.Domain.Installments.Entities.InstallmentContract.Create(
                        contractNumber,
                        sale.Id,
                        customerId,
                        string.IsNullOrWhiteSpace(request.GuarantorName) ? "بدون ضامن" : request.GuarantorName,
                        string.IsNullOrWhiteSpace(request.GuarantorPhone) ? "-" : request.GuarantorPhone,
                        sale.TotalAmount,
                        request.PaidAmount,
                        request.InterestPercentage,
                        request.NumberOfMonths > 0 ? request.NumberOfMonths : 12,
                        request.InstallmentStartDate ?? DateTime.UtcNow.AddMonths(1),
                        request.GuarantorNationalId,
                        request.GuarantorAddress,
                        request.GuarantorNotes,
                        request.Notes);

                    if (contractResult.IsSuccess)
                    {
                        await _salesUnitOfWork.InstallmentContractRepository.AddAsync(contractResult.Value!);
                        sale.AttachInstallmentContract(contractResult.Value!.Id, contractResult.Value!.InterestAmount);
                    }
                }
            }

            await _salesUnitOfWork.SaleRepository.AddAsync(sale);

            var depletedBatches = new List<DepletedBatchDto>();

            // 5. خصم الكمية من المخزون وتسجيل حركة المخزون وخصم دفعات المخزون بنظام FIFO
            foreach (var item in sale.Items)
            {
                var product = await _inventoryUnitOfWork.ProductRepository.GetByIdAsync(item.ProductId, cancellationToken);
                if (product is not null)
                {
                    product.AdjustStock(-item.Quantity, allowNegativeStock);
                    _inventoryUnitOfWork.ProductRepository.Update(product);

                    if (!string.IsNullOrWhiteSpace(item.SerialNumber))
                    {
                        var serial = await _inventoryUnitOfWork.ProductSerialRepository.FindAsync(
                            s => s.ProductId == item.ProductId && s.SerialNumber == item.SerialNumber.Trim());

                        if (serial != null)
                        {
                            serial.MarkAsSold(sale.Id, product.WarrantyPeriodMonths);
                            _inventoryUnitOfWork.ProductSerialRepository.Update(serial);
                        }
                    }

                    // خصم من الدفعات بنظام FIFO الصارم (PurchaseDate ثم CreatedAt)
                    var activeBatches = await _inventoryUnitOfWork.BatchRepository.GetActiveBatchesByProductIdAsync(item.ProductId, cancellationToken);
                    decimal remainingToDeduct = item.Quantity;

                    foreach (var batch in activeBatches)
                    {
                        if (remainingToDeduct <= 0) break;

                        decimal deductAmount = Math.Min(batch.RemainingQuantity, remainingToDeduct);
                        var deductResult = batch.Deduct(deductAmount);
                        if (deductResult.IsSuccess)
                        {
                            _inventoryUnitOfWork.BatchRepository.Update(batch);
                            remainingToDeduct -= deductAmount;

                            if (batch.RemainingQuantity == 0)
                            {
                                depletedBatches.Add(new DepletedBatchDto(
                                    batch.Id,
                                    product.Id,
                                    product.NameAr,
                                    batch.BatchNumber,
                                    batch.OriginalQuantity,
                                    batch.OriginalUnit,
                                    batch.PurchaseDate,
                                    batch.ExpiryDate,
                                    batch.PurchaseInvoiceId
                                ));
                            }
                        }
                    }

                    var movementResult = StockMovement.Create(
                        item.ProductId,
                        -item.Quantity,
                        StockMovementType.Sale,
                        request.CashierId,
                        reference: sale.InvoiceNumber,
                        notes: $"مبيعات فاتورة {sale.InvoiceNumber}");

                    if (movementResult.IsSuccess)
                        await _inventoryUnitOfWork.StockMovementRepository.AddAsync(movementResult.Value!);
                }
            }

            // 6. تحديث إجماليات الشفت
            shift.RecordSale(sale.TotalAmount, sale.DiscountAmount, sale.TaxAmount, sale.PaymentMethod, sale.PaidAmount);
            _shiftsUnitOfWork.ShiftRepository.Update(shift);

            // 7. حفظ التغييرات في كل الوجهات
            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);
            await _inventoryUnitOfWork.SaveChangesAsync(cancellationToken);
            await _shiftsUnitOfWork.SaveChangesAsync(cancellationToken);

            // 8. مسح كاش لوحة التحكم والتقارير الشهرية لضمان تحديث الأرقام فورياً
            await _cacheService.RemoveByPrefixAsync("dashboard_", cancellationToken);
            await _cacheService.RemoveByPrefixAsync("monthly_calendar_", cancellationToken);

            return Result<CreateSaleResult>.Success(new CreateSaleResult(sale.Id, depletedBatches));
        }
    }
}
