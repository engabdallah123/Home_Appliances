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

            // 1. Fetch registered customers from Customers table
            var registeredCustomers = await _db.Customers
                .AsNoTracking()
                .Where(c => c.TenantId == tenantId && c.IsActive)
                .ToListAsync();

            // 2. Fetch sales that have customer info
            var sales = await _db.Sales
                .AsNoTracking()
                .Where(s => s.TenantId == tenantId && s.CustomerName != null && s.CustomerName != "" && s.CustomerName != "Walk-in Customer")
                .Select(s => new
                {
                    CustomerId = s.CustomerId,
                    Name = s.CustomerName!.Trim(),
                    Phone = s.CustomerPhone != null ? s.CustomerPhone.Trim() : null,
                    TotalAmount = s.TotalAmount,
                    RemainingAmount = s.RemainingAmount,
                    SaleDate = s.SaleDate
                })
                .ToListAsync();

            // 3. Fetch debts of type Customer
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

            // Helper dictionary to store customer stats
            var stats = new Dictionary<string, (decimal TotalSpent, decimal TotalDebt, int InvoicesCount, DateTime? LastSaleDate)>(StringComparer.OrdinalIgnoreCase);

            foreach (var s in sales)
            {
                var key = !string.IsNullOrWhiteSpace(s.Phone) ? s.Phone : s.Name;
                if (!stats.TryGetValue(key, out var st))
                {
                    stats[key] = (s.TotalAmount, 0, 1, s.SaleDate);
                }
                else
                {
                    var lastDate = st.LastSaleDate == null || s.SaleDate > st.LastSaleDate ? s.SaleDate : st.LastSaleDate;
                    stats[key] = (st.TotalSpent + s.TotalAmount, st.TotalDebt, st.InvoicesCount + 1, lastDate);
                }
            }

            foreach (var d in debts)
            {
                var key = !string.IsNullOrWhiteSpace(d.Phone) ? d.Phone : d.Name;
                if (!stats.TryGetValue(key, out var st))
                {
                    stats[key] = (0, d.RemainingAmount, 0, null);
                }
                else
                {
                    stats[key] = (st.TotalSpent, st.TotalDebt + d.RemainingAmount, st.InvoicesCount, st.LastSaleDate);
                }
            }

            var result = new List<CloudCustomerDto>();
            var processedKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var rc in registeredCustomers)
            {
                var key = !string.IsNullOrWhiteSpace(rc.Phone) ? rc.Phone : rc.Name;
                processedKeys.Add(key);
                if (!string.IsNullOrWhiteSpace(rc.Name)) processedKeys.Add(rc.Name);
                if (!string.IsNullOrWhiteSpace(rc.Phone)) processedKeys.Add(rc.Phone);

                decimal spent = 0;
                decimal debt = rc.Balance;
                int count = 0;
                DateTime? lastDate = null;

                if (stats.TryGetValue(key, out var st))
                {
                    spent = st.TotalSpent;
                    debt = Math.Max(debt, st.TotalDebt);
                    count = st.InvoicesCount;
                    lastDate = st.LastSaleDate;
                }
                else if (rc.Phone != null && stats.TryGetValue(rc.Phone, out var stPhone))
                {
                    spent = stPhone.TotalSpent;
                    debt = Math.Max(debt, stPhone.TotalDebt);
                    count = stPhone.InvoicesCount;
                    lastDate = stPhone.LastSaleDate;
                }
                else if (stats.TryGetValue(rc.Name, out var stName))
                {
                    spent = stName.TotalSpent;
                    debt = Math.Max(debt, stName.TotalDebt);
                    count = stName.InvoicesCount;
                    lastDate = stName.LastSaleDate;
                }

                result.Add(new CloudCustomerDto(
                    Name: rc.Name,
                    Phone: rc.Phone,
                    TotalSpent: spent,
                    TotalDebt: debt,
                    InvoicesCount: count,
                    LastSaleDate: lastDate,
                    HasDebt: debt > 0,
                    Id: rc.Id,
                    Email: rc.Email,
                    Address: rc.Address
                ));
            }

            // Include any unlinked customers from historical sales/debts
            foreach (var kvp in stats)
            {
                if (processedKeys.Contains(kvp.Key)) continue;

                var isPhone = kvp.Key.All(char.IsDigit) || kvp.Key.StartsWith("+");
                var name = isPhone ? (sales.FirstOrDefault(s => s.Phone == kvp.Key)?.Name ?? debts.FirstOrDefault(d => d.Phone == kvp.Key)?.Name ?? kvp.Key) : kvp.Key;
                var phone = isPhone ? kvp.Key : (sales.FirstOrDefault(s => s.Name == kvp.Key)?.Phone ?? debts.FirstOrDefault(d => d.Name == kvp.Key)?.Phone);

                result.Add(new CloudCustomerDto(
                    Name: name,
                    Phone: phone,
                    TotalSpent: kvp.Value.TotalSpent,
                    TotalDebt: kvp.Value.TotalDebt,
                    InvoicesCount: kvp.Value.InvoicesCount,
                    LastSaleDate: kvp.Value.LastSaleDate,
                    HasDebt: kvp.Value.TotalDebt > 0,
                    Id: null,
                    Email: null,
                    Address: null
                ));
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                result = result.Where(c => c.Name.ToLower().Contains(term) || (c.Phone != null && c.Phone.Contains(term)) || (c.Address != null && c.Address.ToLower().Contains(term))).ToList();
            }

            return Ok(result.OrderByDescending(c => c.TotalDebt).ThenBy(c => c.Name).ToList());
        }

        [HttpPost]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCloudCustomerRequest req)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            if (string.IsNullOrWhiteSpace(req.Name))
                return BadRequest(new { message = "اسم العميل مطلوب." });

            if (string.IsNullOrWhiteSpace(req.Phone))
                return BadRequest(new { message = "رقم هاتف العميل مطلوب." });

            var cleanName = req.Name.Trim();
            var cleanPhone = req.Phone.Trim();

            // Check if customer with same phone already exists for tenant
            var existing = await _db.Customers
                .FirstOrDefaultAsync(c => c.TenantId == tenantId && (c.Phone == cleanPhone || c.Name == cleanName));

            if (existing != null)
            {
                if (!string.IsNullOrWhiteSpace(req.Address) && string.IsNullOrWhiteSpace(existing.Address))
                {
                    existing.Address = req.Address.Trim();
                }
                if (!string.IsNullOrWhiteSpace(req.Email) && string.IsNullOrWhiteSpace(existing.Email))
                {
                    existing.Email = req.Email.Trim();
                }
                existing.IsActive = true;
                existing.UpdatedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();

                return Ok(new CloudCustomerDto(
                    Name: existing.Name,
                    Phone: existing.Phone,
                    TotalSpent: 0,
                    TotalDebt: existing.Balance,
                    InvoicesCount: 0,
                    LastSaleDate: null,
                    HasDebt: existing.Balance > 0,
                    Id: existing.Id,
                    Email: existing.Email,
                    Address: existing.Address
                ));
            }

            var customer = new CloudCustomer
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                Name = cleanName,
                Phone = cleanPhone,
                Email = string.IsNullOrWhiteSpace(req.Email) ? null : req.Email.Trim(),
                Address = string.IsNullOrWhiteSpace(req.Address) ? null : req.Address.Trim(),
                Balance = 0,
                IsActive = true,
                SyncStatus = SyncStatus.PendingSync, // Marked as PendingSync so Desktop sync downloads it to Desktop!
                CreatedAt = DateTime.UtcNow
            };

            _db.Customers.Add(customer);
            await _db.SaveChangesAsync();

            return Ok(new CloudCustomerDto(
                Name: customer.Name,
                Phone: customer.Phone,
                TotalSpent: 0,
                TotalDebt: 0,
                InvoicesCount: 0,
                LastSaleDate: null,
                HasDebt: false,
                Id: customer.Id,
                Email: customer.Email,
                Address: customer.Address
            ));
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
