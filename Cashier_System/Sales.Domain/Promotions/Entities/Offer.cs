using POS.Shared.Domain;

namespace Sales.Domain.Promotions.Entities
{
    public sealed class Offer : Entity
    {
        private readonly List<OfferItem> _items = new();

        public string Title { get; private set; } = default!;
        public string? Description { get; private set; }
        public OfferType Type { get; private set; }

        public decimal? DiscountPercentage { get; private set; }
        public decimal? FixedDiscountAmount { get; private set; }
        public decimal? BundlePrice { get; private set; } // سعر الباقة المجمعة (للبكجات)

        public DateTime StartDate { get; private set; }
        public DateTime EndDate { get; private set; }
        public bool IsActive { get; private set; }

        public Guid? TargetProductId { get; private set; }
        public Guid? TargetCategoryId { get; private set; }
        public Guid? TargetBrandId { get; private set; }

        public DateTime CreatedAt { get; private set; }
        public DateTime? UpdatedAt { get; private set; }

        public IReadOnlyList<OfferItem> Items => _items.AsReadOnly();

        private Offer() { } // EF Core

        private Offer(
            Guid id,
            string title,
            string? description,
            OfferType type,
            decimal? discountPercentage,
            decimal? fixedDiscountAmount,
            decimal? bundlePrice,
            DateTime startDate,
            DateTime endDate,
            Guid? targetProductId,
            Guid? targetCategoryId,
            Guid? targetBrandId) : base(id)
        {
            Title = title.Trim();
            Description = description?.Trim();
            Type = type;
            DiscountPercentage = discountPercentage;
            FixedDiscountAmount = fixedDiscountAmount;
            BundlePrice = bundlePrice;
            StartDate = startDate;
            EndDate = endDate;
            IsActive = true;
            TargetProductId = targetProductId;
            TargetCategoryId = targetCategoryId;
            TargetBrandId = targetBrandId;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<Offer> Create(
            string title,
            string? description,
            OfferType type,
            decimal? discountPercentage,
            decimal? fixedDiscountAmount,
            decimal? bundlePrice,
            DateTime startDate,
            DateTime endDate,
            Guid? targetProductId = null,
            Guid? targetCategoryId = null,
            Guid? targetBrandId = null)
        {
            if (string.IsNullOrWhiteSpace(title))
                return Result<Offer>.Failure(new Error("Offer.TitleRequired", "عنوان العرض مطلوب."));

            if (endDate <= startDate)
                return Result<Offer>.Failure(new Error("Offer.InvalidDates", "تاريخ نهاية العرض يجب أن يكون بعد تاريخ البداية."));

            if (type == OfferType.BundlePackage && (!bundlePrice.HasValue || bundlePrice.Value <= 0))
                return Result<Offer>.Failure(new Error("Offer.BundlePriceRequired", "سعر الباقة الإجمالي مطلوب لعروض البكجات."));

            var offer = new Offer(
                Guid.NewGuid(),
                title,
                description,
                type,
                discountPercentage,
                fixedDiscountAmount,
                bundlePrice,
                startDate,
                endDate,
                targetProductId,
                targetCategoryId,
                targetBrandId);

            return Result<Offer>.Success(offer);
        }

        public Result AddItem(Guid productId, decimal quantity = 1)
        {
            if (Type != OfferType.BundlePackage)
                return Result.Failure(new Error("Offer.NotABundle", "لا يمكن إضافة أصناف إلا لعروض البكجات والمجموعات."));

            var itemResult = OfferItem.Create(Id, productId, quantity);
            if (itemResult.IsFailure)
                return itemResult;

            _items.Add(itemResult.Value!);
            return Result.Success();
        }

        public void ClearItems()
        {
            _items.Clear();
        }

        public void Activate() { IsActive = true; UpdatedAt = DateTime.UtcNow; }
        public void Deactivate() { IsActive = false; UpdatedAt = DateTime.UtcNow; }

        public bool IsCurrentlyValid()
        {
            var now = DateTime.UtcNow;
            return IsActive && now >= StartDate && now <= EndDate;
        }
    }
}
