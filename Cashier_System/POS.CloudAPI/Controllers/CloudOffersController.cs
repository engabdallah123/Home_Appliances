using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using System.Security.Claims;

namespace POS.CloudAPI.Controllers
{
    [ApiController]
    [Route("api/cloud/offers")]
    [Authorize]
    public class CloudOffersController : ControllerBase
    {
        private readonly CloudDbContext _db;

        public CloudOffersController(CloudDbContext db)
        {
            _db = db;
        }

        private Guid GetTenantId()
        {
            var tenantClaim = User.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : Guid.Empty;
        }

        [HttpGet]
        public async Task<IActionResult> GetOffers([FromQuery] string? type = null)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var query = _db.Offers
                .AsNoTracking()
                .Include(o => o.Items)
                .Where(o => o.TenantId == tenantId && o.IsActive);

            if (!string.IsNullOrWhiteSpace(type))
            {
                query = query.Where(o => o.OfferType == type);
            }

            var dbOffers = await query.OrderByDescending(o => o.CreatedAt).ToListAsync();

            if (dbOffers.Any())
            {
                var result = dbOffers.Select(o =>
                {
                    decimal origPrice = o.Items.Sum(i => i.Quantity * i.OriginalUnitPrice);
                    decimal discPrice = origPrice;

                    if (o.BundlePrice.HasValue && o.BundlePrice.Value > 0)
                    {
                        discPrice = o.BundlePrice.Value;
                    }
                    else if (o.FixedDiscountAmount.HasValue && o.FixedDiscountAmount.Value > 0)
                    {
                        discPrice = Math.Max(0, origPrice - o.FixedDiscountAmount.Value);
                    }
                    else if (o.DiscountPercentage.HasValue && o.DiscountPercentage.Value > 0)
                    {
                        discPrice = Math.Max(0, origPrice * (1 - (o.DiscountPercentage.Value / 100m)));
                    }

                    return new
                    {
                        Id = o.Id,
                        TitleAr = o.Title,
                        TitleEn = (string?)null,
                        Description = o.Description,
                        OfferType = o.OfferType,
                        Type = o.Type,
                        DiscountPercentage = (double)(o.DiscountPercentage ?? 0),
                        FixedDiscountAmount = (double)(o.FixedDiscountAmount ?? 0),
                        OriginalPrice = (double)origPrice,
                        DiscountedPrice = (double)discPrice,
                        BundlePrice = (double)(o.BundlePrice ?? 0),
                        StartDate = o.StartDate,
                        EndDate = o.EndDate,
                        IsActive = o.IsActive,
                        IsCurrentlyValid = o.IsActive && o.StartDate <= DateTime.UtcNow && o.EndDate >= DateTime.UtcNow,
                        TargetProductId = o.TargetProductId,
                        TargetProductName = o.TargetProductName,
                        TargetCategoryId = o.TargetCategoryId,
                        TargetCategoryName = o.TargetCategoryName,
                        TargetBrandId = o.TargetBrandId,
                        TargetBrandName = o.TargetBrandName,
                        Items = o.Items.Select(i => new
                        {
                            Id = i.Id,
                            ProductId = i.ProductId,
                            ProductName = i.ProductName,
                            ProductBarcode = i.ProductBarcode,
                            Quantity = (double)i.Quantity,
                            UnitPrice = (double)i.OriginalUnitPrice,
                            SellingPrice = (double)i.OriginalUnitPrice,
                            OriginalUnitPrice = (double)i.OriginalUnitPrice
                        }).ToList()
                    };
                }).ToList();

                return Ok(result);
            }

            return Ok(new List<object>());
        }
    }
}

