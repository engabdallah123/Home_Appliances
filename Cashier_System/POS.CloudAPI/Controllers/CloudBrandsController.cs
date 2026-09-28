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
    [Route("api/cloud/brands")]
    [Authorize]
    public class CloudBrandsController : ControllerBase
    {
        private readonly CloudDbContext _db;

        public CloudBrandsController(CloudDbContext db)
        {
            _db = db;
        }

        private Guid GetTenantId()
        {
            var tenantClaim = User.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : Guid.Empty;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] bool? onlyActive = true)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var query = _db.Brands.AsNoTracking().Where(b => b.TenantId == tenantId);
            if (onlyActive == true)
            {
                query = query.Where(b => b.IsActive);
            }

            var brands = await query
                .OrderBy(b => b.Name)
                .Select(b => new CloudBrandDto(
                    b.Id,
                    b.Name,
                    b.NameAr,
                    b.NameEn,
                    b.Description,
                    b.OriginCountry,
                    b.AgentContactNumber,
                    b.IsActive,
                    b.SyncStatus.ToString()
                ))
                .ToListAsync();

            return Ok(brands);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateCloudBrandRequest req)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var effectiveName = !string.IsNullOrWhiteSpace(req.Name)
                ? req.Name.Trim()
                : (!string.IsNullOrWhiteSpace(req.NameAr) && !string.IsNullOrWhiteSpace(req.NameEn))
                    ? $"{req.NameAr.Trim()} ({req.NameEn.Trim()})"
                    : !string.IsNullOrWhiteSpace(req.NameAr)
                        ? req.NameAr.Trim()
                        : req.NameEn?.Trim() ?? "";

            if (string.IsNullOrWhiteSpace(effectiveName))
                return BadRequest(new { message = "اسم الماركة التجارية مطلوب." });

            var brand = new CloudBrand
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                Name = effectiveName,
                NameAr = req.NameAr?.Trim(),
                NameEn = req.NameEn?.Trim(),
                Description = req.Description?.Trim(),
                OriginCountry = req.OriginCountry?.Trim(),
                AgentContactNumber = req.AgentContactNumber?.Trim(),
                IsActive = true,
                SyncStatus = SyncStatus.PendingSync,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.Brands.Add(brand);
            await _db.SaveChangesAsync();

            return Ok(new CloudBrandDto(
                brand.Id,
                brand.Name,
                brand.NameAr,
                brand.NameEn,
                brand.Description,
                brand.OriginCountry,
                brand.AgentContactNumber,
                brand.IsActive,
                brand.SyncStatus.ToString()
            ));
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCloudBrandRequest req)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var brand = await _db.Brands.FirstOrDefaultAsync(b => b.TenantId == tenantId && b.Id == id);
            if (brand == null) return NotFound(new { message = "الماركة غير موجودة." });

            var effectiveName = !string.IsNullOrWhiteSpace(req.Name)
                ? req.Name.Trim()
                : (!string.IsNullOrWhiteSpace(req.NameAr) && !string.IsNullOrWhiteSpace(req.NameEn))
                    ? $"{req.NameAr.Trim()} ({req.NameEn.Trim()})"
                    : !string.IsNullOrWhiteSpace(req.NameAr)
                        ? req.NameAr.Trim()
                        : req.NameEn?.Trim();

            if (!string.IsNullOrWhiteSpace(effectiveName))
            {
                brand.Name = effectiveName;
            }

            if (req.NameAr != null) brand.NameAr = req.NameAr.Trim();
            if (req.NameEn != null) brand.NameEn = req.NameEn.Trim();
            if (req.Description != null) brand.Description = req.Description.Trim();
            if (req.OriginCountry != null) brand.OriginCountry = req.OriginCountry.Trim();
            if (req.AgentContactNumber != null) brand.AgentContactNumber = req.AgentContactNumber.Trim();
            brand.IsActive = req.IsActive;
            brand.SyncStatus = SyncStatus.PendingSync;
            brand.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return Ok(new CloudBrandDto(
                brand.Id,
                brand.Name,
                brand.NameAr,
                brand.NameEn,
                brand.Description,
                brand.OriginCountry,
                brand.AgentContactNumber,
                brand.IsActive,
                brand.SyncStatus.ToString()
            ));
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var brand = await _db.Brands.FirstOrDefaultAsync(b => b.TenantId == tenantId && b.Id == id);
            if (brand == null) return NotFound();

            brand.IsActive = false;
            brand.SyncStatus = SyncStatus.PendingSync;
            brand.UpdatedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return Ok(new { success = true, message = "تم إلغاء تفعيل الماركة بنجاح." });
        }
    }
}
