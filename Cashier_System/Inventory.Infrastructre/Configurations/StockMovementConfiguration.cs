using Inventory.Domain.Stock.StockMovements;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Inventory.Infrastructre.Configurations;

internal sealed class StockMovementConfiguration : IEntityTypeConfiguration<StockMovement>
{
    public void Configure(EntityTypeBuilder<StockMovement> builder)
    {
        builder.ToTable("StockMovements", Schemas.Inventory);

        builder.HasKey(s => s.Id);

        builder.Property(s => s.ProductId)
            .IsRequired();

        builder.Property(s => s.Quantity)
            .HasPrecision(18, 3)
            .IsRequired();

        builder.Property(s => s.Type)
            .IsRequired();

        builder.Property(s => s.Reference)
            .HasMaxLength(100);

        builder.Property(s => s.Notes)
            .HasMaxLength(500);

        builder.Property(s => s.MovementDate)
            .IsRequired();

        builder.Property(s => s.UserId)
            .IsRequired();

        builder.HasIndex(s => s.ProductId);
        builder.HasIndex(s => s.MovementDate);
        builder.HasIndex(s => s.Type);
    }
}
