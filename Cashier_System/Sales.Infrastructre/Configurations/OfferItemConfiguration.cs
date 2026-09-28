using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;
using Sales.Domain.Promotions.Entities;

namespace Sales.Infrastructre.Configurations;

internal sealed class OfferItemConfiguration : IEntityTypeConfiguration<OfferItem>
{
    public void Configure(EntityTypeBuilder<OfferItem> builder)
    {
        builder.ToTable("OfferItems", Schemas.Sales);

        builder.HasKey(i => i.Id);

        builder.Property(i => i.Quantity)
            .HasPrecision(18, 3)
            .IsRequired();

        builder.HasIndex(i => i.OfferId);
        builder.HasIndex(i => i.ProductId);
    }
}
