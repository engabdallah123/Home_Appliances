using MediatR;
using POS.Shared.Domain;
using Microsoft.EntityFrameworkCore;
using POS.Shared.Application.Exceptions;
using POS.Shared.Infrastructure.Database;
using System.Reflection;
using Returns.Domain.Returns.Entities;

namespace Returns.Infrastructre.Database;

public class ReturnsDbContext : DbContext
{
    private readonly IMediator _mediator;

    public ReturnsDbContext(DbContextOptions<ReturnsDbContext> options, IMediator mediator)
        : base(options)
    {
        _mediator = mediator;
    }

    public DbSet<SalesReturn> SalesReturns { get; set; }
    public DbSet<SalesReturnItem> SalesReturnItems { get; set; }
    public DbSet<PurchaseReturn> PurchaseReturns { get; set; }
    public DbSet<PurchaseReturnItem> PurchaseReturnItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema(Schemas.Returns);
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
