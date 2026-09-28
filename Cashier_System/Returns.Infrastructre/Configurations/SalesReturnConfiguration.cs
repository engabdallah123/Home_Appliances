using Returns.Domain.Returns.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Returns.Infrastructre.Configurations;

internal sealed class SalesReturnConfiguration : IEntityTypeConfiguration<SalesReturn>
{
    public void Configure(EntityTypeBuilder<SalesReturn> builder)
    {
        builder.ToTable("SalesReturns", Schemas.Returns);

        builder.HasKey(r => r.Id);

        builder.Property(r => r.ReturnNumber).IsRequired().HasMaxLength(100);
        builder.HasIndex(r => r.ReturnNumber).IsUnique();

        builder.Property(r => r.OriginalSaleId).IsRequired();
        builder.Property(r => r.CashierId).IsRequired();
        builder.Property(r => r.ShiftId).IsRequired();

        builder.Property(r => r.SubTotal).HasPrecision(18, 2);
        builder.Property(r => r.TaxAmount).HasPrecision(18, 2);
        builder.Property(r => r.TotalAmount).HasPrecision(18, 2);

        builder.Property(r => r.RefundMethod).IsRequired();
        builder.Property(r => r.Reason).HasMaxLength(500);
        builder.Property(r => r.Notes).HasMaxLength(500);

        builder.HasMany(r => r.Items)
            .WithOne()
            .HasForeignKey(i => i.SalesReturnId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
