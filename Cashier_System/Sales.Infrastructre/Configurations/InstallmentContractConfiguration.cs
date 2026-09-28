using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;
using Sales.Domain.Installments.Entities;

namespace Sales.Infrastructre.Configurations;

internal sealed class InstallmentContractConfiguration : IEntityTypeConfiguration<InstallmentContract>
{
    public void Configure(EntityTypeBuilder<InstallmentContract> builder)
    {
        builder.ToTable("InstallmentContracts", Schemas.Sales);

        builder.HasKey(c => c.Id);

        builder.Property(c => c.ContractNumber)
            .IsRequired()
            .HasMaxLength(50);

        builder.HasIndex(c => c.ContractNumber)
            .IsUnique();

        builder.Property(c => c.GuarantorName)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(c => c.GuarantorPhone)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(c => c.GuarantorNationalId)
            .HasMaxLength(50);

        builder.Property(c => c.GuarantorAddress)
            .HasMaxLength(500);

        builder.Property(c => c.GuarantorNotes)
            .HasMaxLength(500);

        builder.Property(c => c.TotalCashAmount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(c => c.DownPayment)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(c => c.InterestPercentage)
            .HasPrecision(5, 2)
            .IsRequired();

        builder.Property(c => c.InterestAmount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(c => c.TotalInstallmentAmount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(c => c.MonthlyInstallmentAmount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(c => c.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(c => c.Notes)
            .HasMaxLength(1000);

        builder.HasMany(c => c.Schedules)
            .WithOne()
            .HasForeignKey(s => s.ContractId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(c => c.CustomerId);
        builder.HasIndex(c => c.SaleId);
        builder.HasIndex(c => c.Status);
    }
}
