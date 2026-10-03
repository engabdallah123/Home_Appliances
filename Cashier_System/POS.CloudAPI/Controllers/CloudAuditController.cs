using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using System.Security.Claims;

namespace POS.CloudAPI.Controllers
{
    [ApiController]
    [Route("api/cloud/audit")]
    [Authorize]
    public class CloudAuditController : ControllerBase
    {
        private readonly CloudDbContext _db;

        public CloudAuditController(CloudDbContext db)
        {
            _db = db;
        }

        private Guid GetTenantId()
        {
            var tenantClaim = User.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : Guid.Empty;
        }

        [HttpGet]
        public async Task<IActionResult> GetAuditLogs(
            [FromQuery] string? entityType,
            [FromQuery] string? status,
            [FromQuery] string? search,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 30)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 30;

            var query = _db.SyncRecords
                .AsNoTracking()
                .Where(r => r.TenantId == tenantId);

            if (!string.IsNullOrWhiteSpace(entityType))
            {
                query = query.Where(r => r.EntityType == entityType);
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(r => r.Status == status);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();
                query = query.Where(r => (r.Details != null && r.Details.Contains(term)) || r.EntityType.Contains(term));
            }

            var totalCount = await query.CountAsync();

            var records = await query
                .OrderByDescending(r => r.Timestamp)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new
                {
                    r.Id,
                    r.EntityType,
                    r.EntityId,
                    r.Direction,
                    r.Status,
                    r.Timestamp,
                    r.Details
                })
                .ToListAsync();

            return Ok(new
            {
                page,
                pageSize,
                totalCount,
                items = records
            });
        }
    }
}
