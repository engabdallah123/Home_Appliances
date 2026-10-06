using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using POS.CloudAPI.Entities;
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
                var targetProductIds = dbOffers
                    .Where(o => o.TargetProductId.HasValue)
                    .Select(o => o.TargetProductId!.Value)
                    .Distinct()
                    .ToList();

                var targetProducts = targetProductIds.Any()
                    ? await _db.Products.AsNoTracking().Where(p => targetProductIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id)
                    : new Dictionary<Guid, CloudProduct>();

                var result = dbOffers.Select(o =>
                {
                    decimal origPrice = 0;
                    if (o.Items != null && o.Items.Any())
                    {
                        origPrice = o.Items.Sum(i => i.Quantity * i.OriginalUnitPrice);
                    }
                    else if (o.TargetProductId.HasValue && targetProducts.TryGetValue(o.TargetProductId.Value, out var tp))
                    {
                        origPrice = tp.SellingPrice;
                    }

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
                        Title = o.Title,
                        TitleAr = o.Title,
                        TitleEn = (string?)null,
                        Description = o.Description,
                        OfferType = o.OfferType,
                        Type = o.Type,
                        DiscountPercentage = (double)(o.DiscountPercentage ?? 0),
                        DiscountPercent = (double)(o.DiscountPercentage ?? 0),
                        FixedDiscountAmount = (double)(o.FixedDiscountAmount ?? 0),
                        DiscountAmount = (double)(o.FixedDiscountAmount ?? 0),
                        BundlePrice = (double)(o.BundlePrice ?? 0),
                        PackagePrice = (double)(o.BundlePrice ?? 0),
                        OriginalPrice = (double)origPrice,
                        DiscountedPrice = (double)discPrice,
                        StartDate = o.StartDate,
                        EndDate = o.EndDate,
                        IsActive = o.IsActive,
                        IsCurrentlyValid = o.IsActive && o.StartDate <= DateTime.UtcNow && o.EndDate >= DateTime.UtcNow,
                        TargetProductId = o.TargetProductId,
                        TargetProductName = o.TargetProductName ?? (o.TargetProductId.HasValue && targetProducts.TryGetValue(o.TargetProductId.Value, out var prod) ? prod.NameAr : null),
                        TargetCategoryId = o.TargetCategoryId,
                        TargetCategoryName = o.TargetCategoryName,
                        TargetBrandId = o.TargetBrandId,
                        TargetBrandName = o.TargetBrandName,
                        Items = (o.Items ?? new List<CloudOfferItem>()).Select(i => new
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

