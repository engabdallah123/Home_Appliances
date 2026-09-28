using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;
using Sales.Domain.Promotions.Entities;

namespace Sales.Infrastructre.Configurations;

internal sealed class OfferConfiguration : IEntityTypeConfiguration<Offer>
{
    public void Configure(EntityTypeBuilder<Offer> builder)
    {
        builder.ToTable("Offers", Schemas.Sales);

        builder.HasKey(o => o.Id);

        builder.Property(o => o.Title)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(o => o.Description)
            .HasMaxLength(1000);

        builder.Property(o => o.Type)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(o => o.DiscountPercentage)
            .HasPrecision(5, 2);

        builder.Property(o => o.FixedDiscountAmount)
            .HasPrecision(18, 2);

        builder.Property(o => o.BundlePrice)
            .HasPrecision(18, 2);

        builder.Property(o => o.IsActive)
            .IsRequired();

        builder.HasMany(o => o.Items)
            .WithOne()
            .HasForeignKey(i => i.OfferId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(o => o.IsActive);
        builder.HasIndex(o => o.Type);
        builder.HasIndex(o => o.StartDate);
        builder.HasIndex(o => o.EndDate);
        builder.HasIndex(o => o.TargetProductId);
        builder.HasIndex(o => o.TargetCategoryId);
        builder.HasIndex(o => o.TargetBrandId);
    }
}
