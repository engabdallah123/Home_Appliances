using Inventory.Domain.Catalog.Units;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using POS.Shared.Infrastructure.Database;

namespace Inventory.Infrastructre.Configurations;

internal sealed class UnitConfiguration : IEntityTypeConfiguration<Unit>
{
    public void Configure(EntityTypeBuilder<Unit> builder)
    {
        builder.ToTable("Units", Schemas.Inventory);

        builder.HasKey(u => u.Id);

        builder.Property(u => u.NameAr)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(u => u.NameEn)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(u => u.Symbol)
            .IsRequired()
            .HasMaxLength(20);
    }
}
