using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using POS.CloudAPI.DTOs;
using POS.CloudAPI.Entities;
using System.Security.Claims;

namespace POS.CloudAPI.Controllers
{
    [ApiController]
    [Route("api/cloud/sales")]
    [Authorize]
    public class CloudSalesController : ControllerBase
    {
        private readonly CloudDbContext _db;

        public CloudSalesController(CloudDbContext db)
        {
            _db = db;
        }

        private Guid GetTenantId()
        {
            var tenantClaim = User.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : Guid.Empty;
        }

        private Guid GetUserId()
        {
            var userClaim = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
            return Guid.TryParse(userClaim, out var userId) ? userId : Guid.Empty;
        }

        [HttpPost]
        public async Task<IActionResult> CreateSale([FromBody] CreateCloudSaleRequest req)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            if (req.Items == null || !req.Items.Any())
                return BadRequest(new { message = "يجب إضافة صنف واحد على الأقل في فاتورة المبيعات." });

            var userId = GetUserId();
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);

            // Generate unique invoice number if not passed
            var invNum = req.InvoiceNumber;
            if (string.IsNullOrWhiteSpace(invNum))
            {
                var todayCount = await _db.Sales.CountAsync(s => s.TenantId == tenantId && s.CreatedAt.Date == DateTime.UtcNow.Date);
                invNum = $"MOB-{DateTime.UtcNow:yyyyMMdd}-{todayCount + 1:D3}";
            }

            // Calculate item totals
            decimal subTotal = 0;
            var saleItems = new List<CloudSaleItem>();

            foreach (var item in req.Items)
            {
                var lineTotal = (item.Quantity * item.UnitPrice) - item.Discount + item.Tax;
                subTotal += lineTotal;

                saleItems.Add(new CloudSaleItem
                {
                    Id = Guid.NewGuid(),
                    ProductId = item.ProductId,
                    ProductName = item.ProductName,
                    Barcode = item.Barcode,
                    ModelNumber = item.ModelNumber,
                    BrandName = item.BrandName,
                    SerialNumber = item.SerialNumber,
                    WarrantyPeriodMonths = item.WarrantyPeriodMonths > 0 ? item.WarrantyPeriodMonths : 12,
                    Quantity = item.Quantity,
                    UnitPrice = item.UnitPrice,
                    Discount = item.Discount,
                    Tax = item.Tax,
                    Total = lineTotal
                });

                // Deduct stock in Cloud Products for live mobile availability
                var product = await _db.Products.FirstOrDefaultAsync(p => p.TenantId == tenantId && p.Id == item.ProductId);
                if (product != null)
                {
                    product.StockQuantity -= item.Quantity;
                }
            }

            var totalAmount = subTotal - req.DiscountAmount + req.TaxAmount;
            var paidAmount = req.PaidAmount;
            if (paidAmount > totalAmount) paidAmount = totalAmount;
            var remainingAmount = totalAmount - paidAmount;

            var sale = new CloudSale
            {
                Id = req.Id ?? Guid.NewGuid(),
                TenantId = tenantId,
                InvoiceNumber = invNum,
                CustomerId = req.CustomerId,
                CustomerName = req.CustomerName,
                CustomerPhone = req.CustomerPhone,
                SaleDate = DateTime.UtcNow,
                SubTotal = subTotal,
                DiscountAmount = req.DiscountAmount,
                TaxAmount = req.TaxAmount,
                TotalAmount = totalAmount,
                PaidAmount = paidAmount,
                RemainingAmount = remainingAmount,
                PaymentMethod = req.PaymentMethod,
                Notes = req.Notes,
                CreatedByUserId = userId,
                CreatedByName = user?.FullName ?? "مندوب المبيعات",
                IsDelivery = req.IsDelivery,
                RecipientName = req.RecipientName,
                RecipientPhone = req.RecipientPhone,
                DeliveryAddress = req.DeliveryAddress,
                DeliveryFloor = req.DeliveryFloor,
                DeliveryFee = req.DeliveryFee,
                IsInstallment = req.IsInstallment,
                GuarantorName = req.GuarantorName,
                GuarantorPhone = req.GuarantorPhone,
                InterestPercentage = req.InterestPercentage,
                NumberOfMonths = req.NumberOfMonths > 0 ? req.NumberOfMonths : 12,
                IsReserved = req.IsReserved,
                TargetDeliveryDate = req.TargetDeliveryDate,
                ReservationStatus = req.ReservationStatus != 0 ? req.ReservationStatus : (req.IsReserved ? 1 : 0),
                SyncStatus = SyncStatus.PendingSync,
                Items = saleItems
            };

            _db.Sales.Add(sale);

            // Record customer debt if remaining balance exists
            if (remainingAmount > 0 && req.CustomerId.HasValue && req.CustomerId != Guid.Empty)
            {
                _db.DebtItems.Add(new CloudDebtItem
                {
                    Id = Guid.NewGuid(),
                    TenantId = tenantId,
                    Type = "Customer",
                    ReferenceId = sale.Id,
                    InvoiceNumber = sale.InvoiceNumber,
                    EntityName = req.CustomerName ?? "عميل آجل",
                    Phone = req.CustomerPhone,
                    TotalAmount = totalAmount,
                    PaidAmount = paidAmount,
                    RemainingAmount = remainingAmount,
                    Date = DateTime.UtcNow
                });
            }

            await _db.SaveChangesAsync();

            var dto = new CloudSaleDto(
                sale.Id,
                sale.InvoiceNumber,
                sale.CustomerId,
                sale.CustomerName,
                sale.CustomerPhone,
                sale.SaleDate,
                sale.SubTotal,
                sale.DiscountAmount,
                sale.TaxAmount,
                sale.TotalAmount,
                sale.PaidAmount,
                sale.RemainingAmount,
                sale.PaymentMethod,
                sale.Notes,
                sale.CreatedByName,
                sale.IsDelivery,
                sale.RecipientName,
                sale.RecipientPhone,
                sale.DeliveryAddress,
                sale.DeliveryFee,
                sale.IsInstallment,
                sale.NumberOfMonths,
                sale.IsReserved,
                sale.SyncStatus.ToString(),
                sale.SyncedAt,
                sale.SyncError,
                sale.Items.Count,
                sale.CreatedAt,
                sale.Items.Select(i => new CloudSaleItemDto(
                    i.Id,
                    i.ProductId,
                    i.ProductName,
                    i.Barcode,
                    i.ModelNumber,
                    i.BrandName,
                    i.SerialNumber,
                    i.WarrantyPeriodMonths,
                    i.Quantity,
                    i.UnitPrice,
                    i.Discount,
                    i.Tax,
                    i.Total)).ToList(),
                sale.ReservationStatus);

            return CreatedAtAction(nameof(GetById), new { id = sale.Id }, dto);
        }

        [HttpGet]
        public async Task<IActionResult> GetSales(
            [FromQuery] string? search,
            [FromQuery] bool? isInstallment = null,
            [FromQuery] bool? isReserved = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 30)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var query = _db.Sales
                .AsNoTracking()
                .Where(s => s.TenantId == tenantId);

            if (isInstallment.HasValue)
            {
                query = query.Where(s => s.IsInstallment == isInstallment.Value);
            }

            if (isReserved.HasValue)
            {
                query = query.Where(s => s.IsReserved == isReserved.Value);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();
                query = query.Where(s =>
                    s.InvoiceNumber.Contains(term) ||
                    (s.CustomerName != null && s.CustomerName.Contains(term)) ||
                    (s.CustomerPhone != null && s.CustomerPhone.Contains(term)) ||
                    (s.RecipientPhone != null && s.RecipientPhone.Contains(term)));
            }

            var sales = await query
                .OrderByDescending(s => s.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(s => new CloudSaleDto(
                    s.Id,
                    s.InvoiceNumber,
                    s.CustomerId,
                    s.CustomerName,
                    s.CustomerPhone,
                    s.SaleDate,
                    s.SubTotal,
                    s.DiscountAmount,
                    s.TaxAmount,
                    s.TotalAmount,
                    s.PaidAmount,
                    s.RemainingAmount,
                    s.PaymentMethod,
                    s.Notes,
                    s.CreatedByName,
                    s.IsDelivery,
                    s.RecipientName,
                    s.RecipientPhone,
                    s.DeliveryAddress,
                    s.DeliveryFee,
                    s.IsInstallment,
                    s.NumberOfMonths,
                    s.IsReserved,
                    s.SyncStatus.ToString(),
                    s.SyncedAt,
                    s.SyncError,
                    s.Items.Count,
                    s.CreatedAt,
                    new List<CloudSaleItemDto>(),
                    s.ReservationStatus))
                .ToListAsync();

            return Ok(sales);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var sale = await _db.Sales
                .AsNoTracking()
                .Include(s => s.Items)
                .FirstOrDefaultAsync(s => s.TenantId == tenantId && s.Id == id);

            if (sale == null) return NotFound();

            var dto = new CloudSaleDto(
                sale.Id,
                sale.InvoiceNumber,
                sale.CustomerId,
                sale.CustomerName,
                sale.CustomerPhone,
                sale.SaleDate,
                sale.SubTotal,
                sale.DiscountAmount,
                sale.TaxAmount,
                sale.TotalAmount,
                sale.PaidAmount,
                sale.RemainingAmount,
                sale.PaymentMethod,
                sale.Notes,
                sale.CreatedByName,
                sale.IsDelivery,
                sale.RecipientName,
                sale.RecipientPhone,
                sale.DeliveryAddress,
                sale.DeliveryFee,
                sale.IsInstallment,
                sale.NumberOfMonths,
                sale.IsReserved,
                sale.SyncStatus.ToString(),
                sale.SyncedAt,
                sale.SyncError,
                sale.Items.Count,
                sale.CreatedAt,
                sale.Items.Select(i => new CloudSaleItemDto(
                    i.Id,
                    i.ProductId,
                    i.ProductName,
                    i.Barcode,
                    i.ModelNumber,
                    i.BrandName,
                    i.SerialNumber,
                    i.WarrantyPeriodMonths,
                    i.Quantity,
                    i.UnitPrice,
                    i.Discount,
                    i.Tax,
                    i.Total)).ToList(),
                sale.ReservationStatus);

            return Ok(dto);
        }

        [HttpPost("{id:guid}/pay-installment")]
        public async Task<IActionResult> PayInstallment(Guid id, [FromBody] PayCloudInstallmentRequest req)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var sale = await _db.Sales.FirstOrDefaultAsync(s => s.Id == id && s.TenantId == tenantId);
            if (sale == null) return NotFound(new { message = "عقد التقسيط غير موجود." });

            if (req.Amount <= 0) return BadRequest(new { message = "يرجى إدخال مبلغ سداد صحيح أكبر من الصفر." });

            var payAmt = Math.Min(req.Amount, sale.RemainingAmount);
            sale.PaidAmount += payAmt;
            sale.RemainingAmount = Math.Max(0, sale.RemainingAmount - payAmt);

            _db.DebtPayments.Add(new CloudDebtPayment
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                DebtType = "Customer",
                ReferenceId = sale.Id,
                Amount = payAmt,
                Notes = req.Notes ?? $"سداد قسط مبيعات رقم {sale.InvoiceNumber}",
                SyncStatus = SyncStatus.PendingSync,
                CreatedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                saleId = sale.Id,
                paidAmount = sale.PaidAmount,
                remainingAmount = sale.RemainingAmount,
                message = $"تم سداد مبلغ {payAmt:N2} ج.م بنجاح."
            });
        }

        [HttpPost("{id:guid}/reservation-status")]
        public async Task<IActionResult> UpdateReservationStatus(Guid id, [FromBody] UpdateReservationStatusRequest req)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var sale = await _db.Sales.FirstOrDefaultAsync(s => s.Id == id && s.TenantId == tenantId);
            if (sale == null) return NotFound(new { message = "فاتورة الحجز غير موجودة." });

            sale.ReservationStatus = req.Status;
            sale.SyncStatus = SyncStatus.PendingSync;

            if (!string.IsNullOrWhiteSpace(req.Notes))
            {
                sale.Notes = string.IsNullOrWhiteSpace(sale.Notes) ? req.Notes : $"{sale.Notes} | {req.Notes}";
            }

            await _db.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                saleId = sale.Id,
                reservationStatus = sale.ReservationStatus,
                message = "تم تحديث حالة الحجز بنجاح وجاهزة للتزامن مع الكاشير."
            });
        }
    }
}
