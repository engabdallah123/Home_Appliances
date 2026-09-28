using Shifts.Domain.Shifts.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Shifts.Infrastructre.Configurations;

internal sealed class ShiftConfiguration : IEntityTypeConfiguration<Shift>
{
    public void Configure(EntityTypeBuilder<Shift> builder)
    {
        builder.ToTable("Shifts", Schemas.Shifts);

        builder.HasKey(s => s.Id);

        builder.Property(s => s.CashierId)
            .IsRequired();

        builder.Property(s => s.OpenedAt)
            .IsRequired();

        builder.Property(s => s.OpeningCash)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(s => s.ClosingCash)
            .HasPrecision(18, 2);

        builder.Property(s => s.SystemCash)
            .HasPrecision(18, 2);

        builder.Property(s => s.CashDifference)
            .HasPrecision(18, 2);

        builder.Property(s => s.TotalSales).HasPrecision(18, 2);
        builder.Property(s => s.TotalCash).HasPrecision(18, 2);
        builder.Property(s => s.TotalCard).HasPrecision(18, 2);
        builder.Property(s => s.TotalWallet).HasPrecision(18, 2);
        builder.Property(s => s.TotalCredit).HasPrecision(18, 2);
        builder.Property(s => s.TotalDiscount).HasPrecision(18, 2);
        builder.Property(s => s.TotalTax).HasPrecision(18, 2);

        builder.Property(s => s.Notes).HasMaxLength(500);
        builder.Property(s => s.ClosingNotes).HasMaxLength(500);

        builder.HasIndex(s => s.CashierId);
        builder.HasIndex(s => s.Status);
        builder.HasIndex(s => s.OpenedAt);
    }
}
