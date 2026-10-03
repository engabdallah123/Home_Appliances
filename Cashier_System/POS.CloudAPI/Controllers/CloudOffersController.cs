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

            // Load top appliance products to dynamically build bundle offers and brand discounts
            var topBrands = await _db.Brands
                .AsNoTracking()
                .Where(b => b.TenantId == tenantId && b.IsActive)
                .Take(6)
                .ToListAsync();

            var topProducts = await _db.Products
                .AsNoTracking()
                .Where(p => p.TenantId == tenantId && p.IsActive)
                .OrderByDescending(p => p.SellingPrice)
                .Take(12)
                .ToListAsync();

            var now = DateTime.UtcNow;

            var offers = new List<object>
            {
                new
                {
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    TitleAr = "بكج جهاز العروسة الماسي المتكامل 🎁",
                    TitleEn = "Diamond Bride Appliance Package",
                    Description = "ثلاجة نوفروست + غسالة فول أوتوماتيك + بوتاجاز أمان كامل 5 شعلة + شاشة سمارت 55 بوصة بخصم خاص وهدية مكنسة كهربائية.",
                    OfferType = "BundlePackage",
                    DiscountPercentage = 15.0,
                    OriginalPrice = 75000.0,
                    DiscountedPrice = 63750.0,
                    StartDate = now.AddDays(-10),
                    EndDate = now.AddDays(30),
                    IsActive = true,
                    IsCurrentlyValid = true,
                    Items = topProducts.Take(4).Select(p => new
                    {
                        p.Id,
                        p.NameAr,
                        p.BrandName,
                        p.ModelNumber,
                        p.SellingPrice
                    }).ToList()
                },
                new
                {
                    Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    TitleAr = "بكج المطبخ الاقتصادي (3 أجهزة)",
                    TitleEn = "Economy Kitchen Bundle",
                    Description = "ثلاجة 14 قدم + بوتاجاز 4 شعلة + غسالة فوق أوتوماتيك مع ضمان شامل وسداد ميسر على 12 شهر.",
                    OfferType = "BundlePackage",
                    DiscountPercentage = 10.0,
                    OriginalPrice = 38000.0,
                    DiscountedPrice = 34200.0,
                    StartDate = now.AddDays(-5),
                    EndDate = now.AddDays(45),
                    IsActive = true,
                    IsCurrentlyValid = true,
                    Items = topProducts.Skip(4).Take(3).Select(p => new
                    {
                        p.Id,
                        p.NameAr,
                        p.BrandName,
                        p.ModelNumber,
                        p.SellingPrice
                    }).ToList()
                }
            };

            // Add brand discounts if brands exist
            if (topBrands.Any())
            {
                var firstBrand = topBrands.First();
                offers.Add(new
                {
                    Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                    TitleAr = $"خصم خاص على جميع أجهزة {firstBrand.Name} 🏷️",
                    TitleEn = $"Special Discount on {firstBrand.Name} Appliances",
                    Description = $"خصم فوري 8% عند شراء أي جهاز من ماركة {firstBrand.Name} كاش أو تقسيط.",
                    OfferType = "BrandDiscount",
                    BrandName = firstBrand.Name,
                    DiscountPercentage = 8.0,
                    OriginalPrice = 0.0,
                    DiscountedPrice = 0.0,
                    StartDate = now.AddDays(-2),
                    EndDate = now.AddDays(20),
                    IsActive = true,
                    IsCurrentlyValid = true,
                    Items = new List<object>()
                });
            }

            if (!string.IsNullOrWhiteSpace(type))
            {
                // Filter by type if passed
                var filtered = offers.Where(o =>
                {
                    var prop = o.GetType().GetProperty("OfferType");
                    return prop != null && (prop.GetValue(o)?.ToString() == type);
                }).ToList();
                return Ok(filtered);
            }

            return Ok(offers);
        }
    }
}
