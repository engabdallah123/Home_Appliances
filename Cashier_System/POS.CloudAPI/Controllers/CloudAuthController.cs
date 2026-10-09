using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using POS.CloudAPI.DTOs;
using POS.CloudAPI.Entities;
using POS.CloudAPI.Services;
using System.Security.Claims;

namespace POS.CloudAPI.Controllers
{
    [ApiController]
    [Route("api/cloud/auth")]
    public class CloudAuthController : ControllerBase
    {
        private readonly CloudDbContext _db;
        private readonly IJwtTokenService _jwt;

        public CloudAuthController(CloudDbContext db, IJwtTokenService jwt)
        {
            _db = db;
            _jwt = jwt;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrWhiteSpace(req.Password))
                return BadRequest(new { message = "اسم المستخدم وكلمة المرور مطلوبان." });

            // Authenticate user directly by username, and load their tenant
            Entities.CloudUser? user;
            if (!string.IsNullOrWhiteSpace(req.ShopCode))
            {
                var tenant = await _db.Tenants.FirstOrDefaultAsync(t => t.Code == req.ShopCode.Trim() && t.IsActive);
                if (tenant == null)
                    return BadRequest(new { message = "كود المتجر / الفرع غير صحيح." });

                user = await _db.Users.FirstOrDefaultAsync(u => u.TenantId == tenant.Id && u.Username == req.Username.Trim() && u.IsActive);
            }
            else
            {
                user = await _db.Users.FirstOrDefaultAsync(u => u.Username == req.Username.Trim() && u.IsActive);
            }

            if (user == null || !CloudDbContext.VerifyPassword(req.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "اسم المستخدم أو كلمة المرور غير صحيحة." });
            }

            var userTenant = await _db.Tenants.FirstOrDefaultAsync(t => t.Id == user.TenantId && t.IsActive);
            if (userTenant == null)
            {
                return Unauthorized(new { message = "المتجر التابع له هذا الحساب غير نشط أو غير موجود." });
            }

            var token = _jwt.GenerateToken(user, userTenant);

            var response = new AuthResponseDto(
                Token: token,
                UserId: user.Id,
                FullName: user.FullName,
                Role: user.Role,
                TenantId: userTenant.Id,
                TenantName: userTenant.Name,
                TenantCode: userTenant.Code,
                ExpiresAt: DateTime.UtcNow.AddDays(30)
            );

            return Ok(response);
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.FullName))
                return BadRequest(new { message = "الاسم مطلوب." });

            if (string.IsNullOrWhiteSpace(req.Username) || string.IsNullOrWhiteSpace(req.Password))
                return BadRequest(new { message = "اسم المستخدم وكلمة المرور مطلوبان." });

            if (req.Password.Trim().Length < 4)
                return BadRequest(new { message = "كلمة المرور يجب ألا تقل عن 4 أحرف أو أرقام." });

            var usernameTrimmed = req.Username.Trim();
            var existingUser = await _db.Users.AnyAsync(u => u.Username.ToLower() == usernameTrimmed.ToLower());
            if (existingUser)
            {
                return BadRequest(new { message = "اسم المستخدم مسجل بالفعل، يرجى اختيار اسم مستخدم آخر." });
            }

            Tenant? tenant = null;
            if (!string.IsNullOrWhiteSpace(req.ShopCode))
            {
                tenant = await _db.Tenants.FirstOrDefaultAsync(t => t.Code == req.ShopCode.Trim() && t.IsActive);
                if (tenant == null)
                    return BadRequest(new { message = "كود المتجر / الفرع غير صحيح." });
            }
            else
            {
                tenant = await _db.Tenants.FirstOrDefaultAsync(t => t.IsActive);
                if (tenant == null)
                {
                    tenant = new Tenant
                    {
                        Id = Guid.NewGuid(),
                        Name = "المتجر الرئيسي",
                        Code = "SHOP01",
                        SyncApiKey = Guid.NewGuid().ToString("N"),
                        IsActive = true,
                        CreatedAt = DateTime.UtcNow
                    };
                    _db.Tenants.Add(tenant);
                    await _db.SaveChangesAsync();
                }
            }

            var newUser = new Entities.CloudUser
            {
                Id = Guid.NewGuid(),
                TenantId = tenant.Id,
                Username = usernameTrimmed,
                PasswordHash = CloudDbContext.HashPassword(req.Password.Trim()),
                FullName = req.FullName.Trim(),
                Role = "Cashier",
                Phone = req.Phone?.Trim() ?? "",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _db.Users.Add(newUser);
            await _db.SaveChangesAsync();

            var token = _jwt.GenerateToken(newUser, tenant);

            var response = new AuthResponseDto(
                Token: token,
                UserId: newUser.Id,
                FullName: newUser.FullName,
                Role: newUser.Role,
                TenantId: tenant.Id,
                TenantName: tenant.Name,
                TenantCode: tenant.Code,
                ExpiresAt: DateTime.UtcNow.AddDays(30)
            );

            return Ok(response);
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> GetProfile()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var user = await _db.Users.FindAsync(userId);
            if (user == null) return NotFound();

            var tenant = await _db.Tenants.FindAsync(user.TenantId);

            return Ok(new
            {
                user.Id,
                user.Username,
                user.FullName,
                user.Role,
                user.Phone,
                Tenant = new
                {
                    tenant?.Id,
                    tenant?.Name,
                    tenant?.Code
                }
            });
        }

        [Authorize]
        [HttpGet("users")]
        public async Task<IActionResult> GetTenantUsers()
        {
            var tenantIdClaim = User.FindFirstValue("TenantId");
            if (!Guid.TryParse(tenantIdClaim, out var tenantId))
                return Unauthorized();

            var users = await _db.Users
                .AsNoTracking()
                .Where(u => u.TenantId == tenantId)
                .OrderBy(u => u.FullName)
                .Select(u => new
                {
                    u.Id,
                    u.Username,
                    u.FullName,
                    u.Role,
                    u.Phone,
                    u.IsActive,
                    u.CreatedAt
                })
                .ToListAsync();

            return Ok(users);
        }
    }
}
