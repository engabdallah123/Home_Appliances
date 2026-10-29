using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using POS.CloudAPI.DTOs;
using System.Security.Claims;

namespace POS.CloudAPI.Controllers
{
    [ApiController]
    [Route("api/cloud/customers")]
    [Authorize]
    public class CloudCustomersController : ControllerBase
    {
        private readonly CloudDbContext _db;

        public CloudCustomersController(CloudDbContext db)
        {
            _db = db;
        }

        private Guid GetTenantId()
        {
            var tenantClaim = User.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : Guid.Empty;
        }

        [HttpGet]
        public async Task<IActionResult> GetCustomers([FromQuery] string? search)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            // 1. Fetch sales that have customer info
            var sales = await _db.Sales
                .AsNoTracking()
                .Where(s => s.TenantId == tenantId && s.CustomerName != null && s.CustomerName != "" && s.CustomerName != "Walk-in Customer")
                .Select(s => new
                {
                    Name = s.CustomerName!.Trim(),
                    Phone = s.CustomerPhone != null ? s.CustomerPhone.Trim() : null,
                    TotalAmount = s.TotalAmount,
                    RemainingAmount = s.RemainingAmount,
                    SaleDate = s.SaleDate
                })
                .ToListAsync();

            // 2. Fetch debts of type Customer
            var debts = await _db.DebtItems
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.Type == "Customer")
                .Select(d => new
                {
                    Name = d.EntityName.Trim(),
                    Phone = d.Phone != null ? d.Phone.Trim() : null,
                    RemainingAmount = d.RemainingAmount
                })
                .ToListAsync();

            // 3. Aggregate by Normalized Name / Phone
            var customerMap = new Dictionary<string, (string Name, string? Phone, decimal TotalSpent, decimal TotalDebt, int InvoicesCount, DateTime? LastSaleDate)>(StringComparer.OrdinalIgnoreCase);

            foreach (var s in sales)
            {
                var key = !string.IsNullOrWhiteSpace(s.Phone) ? s.Phone : s.Name;
                if (!customerMap.TryGetValue(key, out var existing))
                {
                    customerMap[key] = (s.Name, s.Phone, s.TotalAmount, 0, 1, s.SaleDate);
                }
                else
                {
                    var lastDate = existing.LastSaleDate == null || s.SaleDate > existing.LastSaleDate ? s.SaleDate : existing.LastSaleDate;
                    customerMap[key] = (
                        string.IsNullOrWhiteSpace(existing.Name) ? s.Name : existing.Name,
                        string.IsNullOrWhiteSpace(existing.Phone) ? s.Phone : existing.Phone,
                        existing.TotalSpent + s.TotalAmount,
                        existing.TotalDebt,
                        existing.InvoicesCount + 1,
                        lastDate
                    );
                }
            }

            foreach (var d in debts)
            {
                var key = !string.IsNullOrWhiteSpace(d.Phone) ? d.Phone : d.Name;
                if (!customerMap.TryGetValue(key, out var existing))
                {
                    customerMap[key] = (d.Name, d.Phone, 0, d.RemainingAmount, 0, null);
                }
                else
                {
                    customerMap[key] = (
                        existing.Name,
                        existing.Phone,
                        existing.TotalSpent,
                        existing.TotalDebt + d.RemainingAmount,
                        existing.InvoicesCount,
                        existing.LastSaleDate
                    );
                }
            }

            var result = customerMap.Values
                .Select(c => new CloudCustomerDto(
                    Name: c.Name,
                    Phone: c.Phone,
                    TotalSpent: c.TotalSpent,
                    TotalDebt: c.TotalDebt,
                    InvoicesCount: c.InvoicesCount,
                    LastSaleDate: c.LastSaleDate,
                    HasDebt: c.TotalDebt > 0
                ));

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                result = result.Where(c => c.Name.ToLower().Contains(term) || (c.Phone != null && c.Phone.Contains(term)));
            }

            return Ok(result.OrderByDescending(c => c.TotalDebt).ThenBy(c => c.Name).ToList());
        }

        [HttpGet("dossier")]
        public async Task<IActionResult> GetCustomerDossier([FromQuery] string? name, [FromQuery] string? phone)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            if (string.IsNullOrWhiteSpace(name) && string.IsNullOrWhiteSpace(phone))
            {
                return BadRequest("يرجى تحديد اسم أو هاتف العميل.");
            }

            var cleanPhone = phone?.Trim();
            var cleanName = name?.Trim();

            var salesQuery = _db.Sales
                .AsNoTracking()
                .Where(s => s.TenantId == tenantId);

            if (!string.IsNullOrWhiteSpace(cleanPhone))
            {
                salesQuery = salesQuery.Where(s => s.CustomerPhone == cleanPhone || s.RecipientPhone == cleanPhone || s.CustomerName == cleanName);
            }
            else
            {
                salesQuery = salesQuery.Where(s => s.CustomerName == cleanName);
            }

            var sales = await salesQuery
                .OrderByDescending(s => s.SaleDate)
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
                    s.ReservationStatus,
                    s.InterestPercentage,
                    s.GuarantorName,
                    s.GuarantorPhone
                ))
                .ToListAsync();

            var debtsQuery = _db.DebtItems
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.Type == "Customer");

            if (!string.IsNullOrWhiteSpace(cleanPhone))
            {
                debtsQuery = debtsQuery.Where(d => d.Phone == cleanPhone || d.EntityName == cleanName);
            }
            else
            {
                debtsQuery = debtsQuery.Where(d => d.EntityName == cleanName);
            }

            var debts = await debtsQuery
                .OrderByDescending(d => d.Date)
                .Select(d => new CloudDebtDto(
                    d.Id,
                    d.Type,
                    d.ReferenceId,
                    d.InvoiceNumber,
                    d.EntityName,
                    d.Phone,
                    d.TotalAmount,
                    d.PaidAmount,
                    d.RemainingAmount,
                    d.Date
                ))
                .ToListAsync();

            var totalSpent = sales.Sum(s => s.TotalAmount);
            var totalDebt = debts.Sum(d => d.RemainingAmount);

            return Ok(new CloudCustomerDossierDto(
                Name: cleanName ?? (sales.FirstOrDefault()?.CustomerName ?? "عميل"),
                Phone: cleanPhone ?? (sales.FirstOrDefault()?.CustomerPhone),
                TotalSpent: totalSpent,
                TotalDebt: totalDebt,
                Sales: sales,
                Debts: debts
            ));
        }
    }
}
