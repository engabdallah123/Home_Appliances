using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;
using Sales.Domain.Installments.Entities;

namespace Sales.Infrastructre.Configurations;

internal sealed class InstallmentScheduleConfiguration : IEntityTypeConfiguration<InstallmentSchedule>
{
    public void Configure(EntityTypeBuilder<InstallmentSchedule> builder)
    {
        builder.ToTable("InstallmentSchedules", Schemas.Sales);

        builder.HasKey(s => s.Id);

        builder.Property(s => s.Amount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(s => s.PaidAmount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(s => s.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(s => s.PaymentMethod)
            .HasMaxLength(50);

        builder.Property(s => s.Notes)
            .HasMaxLength(500);

        builder.HasIndex(s => s.ContractId);
        builder.HasIndex(s => s.DueDate);
        builder.HasIndex(s => s.Status);
    }
}
