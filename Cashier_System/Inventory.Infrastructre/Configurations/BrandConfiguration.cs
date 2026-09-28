using Inventory.Domain.Catalog.Brands;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Inventory.Infrastructre.Configurations;

internal sealed class BrandConfiguration : IEntityTypeConfiguration<Brand>
{
    public void Configure(EntityTypeBuilder<Brand> builder)
    {
        builder.ToTable("Brands", Schemas.Inventory);

        builder.HasKey(b => b.Id);

        builder.Property(b => b.Name)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(b => b.NameAr)
            .HasMaxLength(150);

        builder.Property(b => b.NameEn)
            .HasMaxLength(150);

        builder.Property(b => b.Description)
            .HasMaxLength(500);

        builder.Property(b => b.OriginCountry)
            .HasMaxLength(100);

        builder.Property(b => b.AgentContactNumber)
            .HasMaxLength(50);

        builder.HasIndex(b => b.Name).IsUnique();
        builder.HasIndex(b => b.IsActive);
    }
}
