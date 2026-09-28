using Purchases.Domain.Purchases.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Purchases.Infrastructre.Configurations;

internal sealed class PurchaseItemConfiguration : IEntityTypeConfiguration<PurchaseItem>
{
    public void Configure(EntityTypeBuilder<PurchaseItem> builder)
    {
        builder.ToTable("PurchaseItems", Schemas.Purchases);

        builder.HasKey(i => i.Id);

        builder.Property(i => i.ProductId)
            .IsRequired();

        builder.Property(i => i.Quantity)
            .HasPrecision(18, 3)
            .IsRequired();

        builder.Property(i => i.UnitCost)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(i => i.Discount).HasPrecision(18, 2);
        builder.Property(i => i.Tax).HasPrecision(18, 2);
        builder.Property(i => i.Total).HasPrecision(18, 2);

        builder.Property(i => i.BatchNumber).HasMaxLength(50);
    }
}
