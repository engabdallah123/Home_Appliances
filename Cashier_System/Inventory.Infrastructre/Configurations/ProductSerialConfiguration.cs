using Inventory.Domain.Catalog.Products.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Inventory.Infrastructre.Configurations;

internal sealed class ProductSerialConfiguration : IEntityTypeConfiguration<ProductSerial>
{
    public void Configure(EntityTypeBuilder<ProductSerial> builder)
    {
        builder.ToTable("ProductSerials", Schemas.Inventory);

        builder.HasKey(ps => ps.Id);

        builder.Property(ps => ps.SerialNumber)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(ps => ps.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(ps => ps.Notes)
            .HasMaxLength(500);

        builder.HasIndex(ps => new { ps.ProductId, ps.SerialNumber })
            .IsUnique();

        builder.HasIndex(ps => ps.SerialNumber);
        builder.HasIndex(ps => ps.Status);
        builder.HasIndex(ps => ps.SaleId);
        builder.HasIndex(ps => ps.PurchaseId);
    }
}
