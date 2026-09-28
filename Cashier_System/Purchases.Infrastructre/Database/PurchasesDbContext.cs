using MediatR;
using POS.Shared.Domain;
using Microsoft.EntityFrameworkCore;
using POS.Shared.Application.Exceptions;
using POS.Shared.Infrastructure.Database;
using System.Reflection;
using Purchases.Domain.Purchases.Entities;
using Purchases.Domain.Suppliers.Entities;

namespace Purchases.Infrastructre.Database;

public class PurchasesDbContext : DbContext
{
    private readonly IMediator _mediator;

    public PurchasesDbContext(DbContextOptions<PurchasesDbContext> options, IMediator mediator)
        : base(options)
    {
        _mediator = mediator;
    }

    public DbSet<Supplier> Suppliers { get; set; }
    public DbSet<Purchase> Purchases { get; set; }
    public DbSet<PurchaseItem> PurchaseItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema(Schemas.Purchases);
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var domainEvents = ChangeTracker
                .Entries<Entity>()
                .Select(e => e.Entity)
                .Where(e => e.GetDomainEvents().Any())
                .SelectMany(e =>
                {
                    var events = e.GetDomainEvents().ToList();
                    e.ClearDomainEvents();
                    return events;
                })
                .ToList();

            var result = await base.SaveChangesAsync(cancellationToken);

            foreach (var domainEvent in domainEvents)
                await _mediator.Publish(domainEvent, cancellationToken);

            return result;
        }
        catch (DbUpdateConcurrencyException ex)
        {
            var entry = ex.Entries.FirstOrDefault();
            var entityName = entry?.Metadata.ClrType.Name ?? "Unknown Entity";
            var state = entry?.State.ToString() ?? "Unknown State";

            throw new ConcurrencyException(
                $"Concurrency error on Entity: '{entityName}' | State: '{state}'.", ex);
        }
    }
}
