using Purchases.Domain.Purchases.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Purchases.Infrastructre.Configurations;

internal sealed class PurchaseConfiguration : IEntityTypeConfiguration<Purchase>
{
    public void Configure(EntityTypeBuilder<Purchase> builder)
    {
        builder.ToTable("Purchases", Schemas.Purchases);

        builder.HasKey(p => p.Id);

        builder.Property(p => p.InvoiceNumber)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(p => p.InternalNumber)
            .HasMaxLength(100);

        builder.Property(p => p.SupplierId)
            .IsRequired();

        builder.Property(p => p.SubTotal).HasPrecision(18, 2);
        builder.Property(p => p.DiscountAmount).HasPrecision(18, 2);
        builder.Property(p => p.TaxAmount).HasPrecision(18, 2);
        builder.Property(p => p.TotalAmount).HasPrecision(18, 2);
        builder.Property(p => p.PaidAmount).HasPrecision(18, 2);
        builder.Property(p => p.RemainingAmount).HasPrecision(18, 2);

        builder.Property(p => p.Notes).HasMaxLength(500);

        builder.HasMany(p => p.Items)
            .WithOne()
            .HasForeignKey(i => i.PurchaseId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => p.SupplierId);
        builder.HasIndex(p => p.InvoiceNumber);
        builder.HasIndex(p => p.PurchaseDate);
    }
}
