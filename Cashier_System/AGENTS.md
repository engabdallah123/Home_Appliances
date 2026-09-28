# POS Cashier System — Agent Guidelines

> This document is auto-generated from the actual codebase.
> It tells AI agents exactly how this project is structured and how to extend it.

---

## 1. Solution Overview

| Layer | Project | Purpose |
|---|---|---|
| **Shared Domain** | `POS.Shared.Domain` | `Entity`, `Result<T>`, `Error`, `IBaseRepository<T>`, `IDomainEvent`, `IUnitOfWork` |
| **Shared Application** | `POS.Shared.Application` | `ICommand`, `IQuery`, handlers, `ValidationBehavior`, `LoggingBehavior`, `ISqlConnectionFactory` |
| **Shared Infrastructure** | `POS.Shared.Infrastructre` | `BaseRepository<T>`, `Schemas`, `SqlConnectionFactory`, `FileService` |
| **Module Domain** | `{Module}.Domain` | Entities, Value Objects, Errors, Domain Events, Repository interfaces |
| **Module Application** | `{Module}.Application` | Commands, Queries, Handlers, Validators, DI |
| **Module Infrastructure** | `{Module}.Infrastructre` | DbContext, EF Configurations, Repository implementations, UnitOfWork, DI |
| **Host** | `POS.WebAPI` | ASP.NET Core Web API — controllers, Program.cs |

**Target framework:** `net10.0`
**Database:** SQL Server via `Microsoft.EntityFrameworkCore.SqlServer 10.0.10`
**ORM:** EF Core 10 (write) + Dapper (read, via `ISqlConnectionFactory`)
**CQRS:** MediatR 14.2.0
**Validation:** FluentValidation 12.1.1
**Logging:** Serilog

---

## 2. Architecture Patterns

### Clean Architecture
```
Domain ← Application ← Infrastructure ← Presentation (WebAPI)
```
- Domain has **zero** infrastructure dependencies.
- Application references Domain + Shared Application.
- Infrastructure references Application + Domain + Shared Infrastructure.
- WebAPI references Infrastructure (which transitively brings the rest).

### DDD (Domain-Driven Design)
- Each module is split into **sub-domains** (e.g., `Catalog`, `Stock`, `Pricing`).
- Entities inherit from `POS.Shared.Domain.Entity` (Guid Id, domain events).
- Value Objects implement `IEquatable<T>` with a static `Create()` factory returning `Result<T>`.
- Business rules live inside Entities (rich domain model).
- Errors are defined as static classes per entity (e.g., `ProductErrors`).

### CQRS
- **Commands** implement `ICommand` or `ICommand<TResponse>` (both return `Result`/`Result<T>`).
- **Queries** implement `IQuery<TResponse>` (returns `Result<T>`).
- **Handlers** implement `ICommandHandler<TCommand>` / `ICommandHandler<TCommand, TResponse>` / `IQueryHandler<TQuery, TResponse>`.
- Commands go through `ValidationBehavior` + `LoggingBehavior` pipeline.

### Result Pattern
```csharp
Result.Success();
Result.Failure(error);
Result<T>.Success(value);
Result<T>.Failure(error);
```

### Unit of Work
- Each module has its own `I{Module}UnitOfWork` interface (in Domain) exposing repository properties + `SaveChangesAsync()`.
- Implementation lives in Infrastructure, wrapping the module's `DbContext`.

### Repository Pattern
- `IBaseRepository<T>` in `POS.Shared.Domain` — generic CRUD, Find, Pagination, Where.
- `BaseRepository<T>` in `POS.Shared.Infrastructure.Database` — EF Core implementation.
- Module-specific repositories extend `IBaseRepository<T>` only when specialized queries are needed.

---

## 3. Project Structure Convention

### Domain Project (`{Module}.Domain`)
```
{Module}.Domain/
├── {SubDomain}/
│   └── {EntityName}/
│       ├── Entities/           # Entity classes + Value Objects
│       ├── Errors/             # Static error classes
│       ├── Events/             # Domain Events (internal to module)
│       └── Interface/          # Repository interface (only if needed)
├── I{Module}UnitOfWork.cs
└── {Module}.Domain.csproj      # References: POS.Shared.Domain
```

### Application Project (`{Module}.Application`)
```
{Module}.Application/
├── {SubDomain}/
│   └── {EntityName}/
│       ├── Commands/
│       │   └── {CommandName}/
│       │       ├── {CommandName}Command.cs
│       │       ├── {CommandName}CommandHandler.cs
│       │       └── {CommandName}CommandValidator.cs
│       └── Queries/
│           └── {QueryName}/
│               ├── {QueryName}Query.cs
│               ├── {QueryName}QueryHandler.cs
│               └── {QueryName}Response.cs (DTO)
├── DependencyInjection.cs
└── {Module}.Application.csproj  # References: {Module}.Domain, POS.Shared.Application
```

### Infrastructure Project (`{Module}.Infrastructre`)
```
{Module}.Infrastructre/
├── Database/
│   └── {Module}DbContext.cs
├── Configurations/
│   └── {EntityName}Configuration.cs
├── Repositories/
│   └── {subdomain}/
│       └── {EntityName}Repository.cs
├── {Module}UnitOfWork.cs
├── DependencyInjection.cs
└── {Module}.Infrastructre.csproj  # References: {Module}.Application, {Module}.Domain, POS.Shared.Infrastructre
```

---

## 4. Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Entity | PascalCase, sealed class | `Product`, `Warehouse` |
| Value Object | PascalCase, sealed class, `IEquatable<T>` | `Sku`, `Money` |
| Error class | `{Entity}Errors` static class | `ProductErrors`, `WarehouseErrors` |
| Error field | Descriptive name | `NameRequired`, `InsufficientStock` |
| Domain Event | `{Entity}{Action}DomainEvent` record | `ProductCreatedDomainEvent` |
| Integration Event | `{Entity}{Action}IntegrationEvent` record | `ProductStockChangedIntegrationEvent` |
| Command | `{Action}{Entity}Command` record | `CreateProductCommand` |
| Command Handler | `{Action}{Entity}CommandHandler` | `CreateProductCommandHandler` |
| Validator | `{Action}{Entity}CommandValidator` | `CreateProductCommandValidator` |
| Query | `Get{Entity/Entities}{Criteria}Query` record | `GetProductByIdQuery` |
| Query Handler | `Get{Entity}{Criteria}QueryHandler` | `GetProductByIdQueryHandler` |
| Response DTO | `{Entity}Response` record | `ProductResponse` |
| Repository Interface | `I{Entity}Repository` | `IProductRepository` |
| Repository Impl | `{Entity}Repository` | `ProductRepository` |
| DbContext | `{Module}DbContext` | `InventoryDbContext` |
| EF Configuration | `{Entity}Configuration` | `ProductConfiguration` |
| UnitOfWork Interface | `I{Module}UnitOfWork` | `IInventoryUnitOfWork` |
| UnitOfWork Impl | `{Module}UnitOfWork` | `InventoryUnitOfWork` |
| DI Extension | `Add{Module}{Layer}` | `AddInventoryApplication()`, `AddInventoryInfrastructure()` |
| DB Schema | `Schemas.{Module}` | `Schemas.Inventory` |
| Namespace | Matches folder structure | `Inventory.Domain.Catalog.Products.Entities` |

---

## 5. Entity Convention

```csharp
public sealed class Product : Entity
{
    // Properties — private set
    public string Name { get; private set; } = default!;

    // Parameterless ctor for EF Core
    private Product() { }

    // Private ctor with all params
    private Product(Guid id, ...) : base(id) { ... }

    // Static factory method returning Result<T>
    public static Result<Product> Create(...) { ... }

    // Domain methods returning Result
    public Result Activate() { ... }
}
```

---

## 6. Value Object Convention

```csharp
public sealed class Sku : IEquatable<Sku>
{
    public string Value { get; }
    private Sku(string value) => Value = value;

    public static Result<Sku> Create(string value)
    {
        // validation
        return Result<Sku>.Success(new Sku(value));
    }

    public bool Equals(Sku? other) => ...;
    public override bool Equals(object? obj) => ...;
    public override int GetHashCode() => ...;
}
```

---

## 7. Error Convention

```csharp
public static class ProductErrors
{
    public static Error NotFound(Guid id) =>
        new("Product.NotFound", $"المنتج بالرقم '{id}' غير موجود.");

    public static readonly Error DuplicateSku =
        Error.Conflict("Product.DuplicateSku", "يوجد بالفعل منتج بنفس الـ SKU.");
}
```
- Error code format: `{Entity}.{ErrorName}`
- Error messages are in Arabic (project convention).

---

## 8. Domain Event Convention

**Internal (within module):**
```csharp
// In {Module}.Domain/{SubDomain}/{Entity}/Events/
public sealed record ProductCreatedDomainEvent(Guid ProductId, string Sku) : IDomainEvent;
```

**Integration (cross-module):**
```csharp
// In POS.Shared.Domain/Events/{Module}/
public sealed record ProductStockChangedIntegrationEvent(
    Guid ProductId, string Sku, int NewQuantity, bool IsLowStock) : IDomainEvent;
```

Events are raised via `RaiseDomainEvent()` inside Entity methods.
Events are published in `SaveChangesAsync()` override in DbContext via MediatR.

---

## 9. Command / Query Convention

```csharp
// Command
public sealed record CreateProductCommand(string Name, ...) : ICommand<Guid>;

// Handler
internal sealed class CreateProductCommandHandler : ICommandHandler<CreateProductCommand, Guid>
{
    public async Task<Result<Guid>> Handle(CreateProductCommand request, CancellationToken ct) { ... }
}

// Validator
internal sealed class CreateProductCommandValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductCommandValidator() { RuleFor(x => x.Name).NotEmpty(); }
}

// Query
public sealed record GetProductByIdQuery(Guid Id) : IQuery<ProductResponse>;

// Query Handler
internal sealed class GetProductByIdQueryHandler : IQueryHandler<GetProductByIdQuery, ProductResponse>
{
    public async Task<Result<ProductResponse>> Handle(GetProductByIdQuery request, CancellationToken ct) { ... }
}

// Response DTO
public sealed record ProductResponse(Guid Id, string Name, string Sku, ...);
```

---

## 10. EF Core Configuration Convention

```csharp
internal sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products", Schemas.Inventory);
        builder.HasKey(p => p.Id);
        // Owned types for Value Objects
        builder.OwnsOne(p => p.Sku, sku => { sku.Property(s => s.Value).HasColumnName("Sku").HasMaxLength(50); });
        builder.OwnsOne(p => p.Price, price => { ... });
        // Indexes
        builder.HasIndex(...).IsUnique();
    }
}
```

- All configurations in `{Module}.Infrastructre/Configurations/`.
- Schema from `Schemas.{Module}`.
- Applied via `modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly())`.

---

## 11. DbContext Convention

```csharp
public class InventoryDbContext : DbContext
{
    private readonly IMediator _mediator;

    public InventoryDbContext(DbContextOptions<InventoryDbContext> options, IMediator mediator)
        : base(options) { _mediator = mediator; }

    public DbSet<Product> Products { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema(Schemas.Inventory);
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }

    // Override SaveChangesAsync to dispatch domain events after save
    public override async Task<int> SaveChangesAsync(CancellationToken ct = default) { ... }
}
```

---

## 12. Repository Convention

Only create a repository interface when `IBaseRepository<T>` is insufficient.

```csharp
// Domain
public interface IProductRepository
{
    Task<Product?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<bool> SkuExistsAsync(string sku, CancellationToken ct = default);
}

// Infrastructure
public class ProductRepository : IProductRepository
{
    private readonly InventoryDbContext _context;
    public ProductRepository(InventoryDbContext context) { _context = context; }
    // implement methods using _context
}
```

---

## 13. Unit of Work Convention

```csharp
// Domain
public interface IInventoryUnitOfWork
{
    IProductRepository ProductRepository { get; }
    Task<int> SaveChangesAsync(CancellationToken ct = default);
}

// Infrastructure
public class InventoryUnitOfWork : IInventoryUnitOfWork
{
    private readonly InventoryDbContext _dbContext;
    public IProductRepository ProductRepository { get; private set; }

    public InventoryUnitOfWork(InventoryDbContext dbContext)
    {
        _dbContext = dbContext;
        ProductRepository = new ProductRepository(_dbContext);
    }

    public async Task<int> SaveChangesAsync(CancellationToken ct = default)
        => await _dbContext.SaveChangesAsync(ct);
}
```

---

## 14. Dependency Injection Convention

**Application DI:**
```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddInventoryApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly));
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly, includeInternalTypes: true);
        return services;
    }
}
```

**Infrastructure DI:**
```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddInventoryInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        services.AddDbContext<InventoryDbContext>(options => options.UseSqlServer(connectionString));
        services.AddScoped<IInventoryUnitOfWork, InventoryUnitOfWork>();
        return services;
    }
}
```

**Program.cs registration:**
```csharp
builder.Services.AddSharedApplication();
builder.Services.AddSharedInfrastructure(builder.Configuration);
builder.Services.AddInventoryApplication();
builder.Services.AddInventoryInfrastructure(builder.Configuration);
```

---

## 15. Controller Convention

```csharp
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ISender _sender;
    public ProductsController(ISender sender) { _sender = sender; }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateProductCommand command)
    {
        var result = await _sender.Send(command);
        if (result.IsFailure) return BadRequest(result.Error);
        return CreatedAtAction(nameof(GetById), new { id = result.Value }, result.Value);
    }
}
```

---

## 16. Database Schemas

Defined in `POS.Shared.Infrastructure.Database.Schemas`:
```csharp
public static class Schemas
{
    public const string Inventory = "Inventory";
    public const string Sales = "Sales";
    public const string Purchases = "Purchases";
    public const string Finance = "Finance";
    public const string Pharmacy = "Pharmacy";
}
```

---

## 17. Integration Events (Cross-Module)

Place in `POS.Shared.Domain/Events/{Module}/`.
These events allow modules to communicate without direct references.
Example: When stock changes in Inventory, Sales module can listen to `ProductStockChangedIntegrationEvent`.

---

## 18. How to Add a New Module

1. Create `{Module}.Domain` project → reference `POS.Shared.Domain`.
2. Create `{Module}.Application` project → reference `{Module}.Domain` + `POS.Shared.Application`.
3. Create `{Module}.Infrastructre` project → reference `{Module}.Application` + `{Module}.Domain` + `POS.Shared.Infrastructre`.
4. Add all three projects to `Cashier_System.slnx`.
5. Add `{Module}.Infrastructre` reference to `POS.WebAPI.csproj`.
6. Create DI extension methods and register in `Program.cs`.

## 19. How to Add a New Entity

1. Create entity class in `{Module}.Domain/{SubDomain}/{Entity}/Entities/` inheriting `Entity`.
2. Create error class in `{Module}.Domain/{SubDomain}/{Entity}/Errors/`.
3. Create domain events in `{Module}.Domain/{SubDomain}/{Entity}/Events/` if needed.
4. Create repository interface in `{Module}.Domain/{SubDomain}/{Entity}/Interface/` only if `IBaseRepository` is not enough.
5. Add `DbSet<T>` in `{Module}DbContext`.
6. Create EF Configuration in `{Module}.Infrastructre/Configurations/`.
7. Implement repository in `{Module}.Infrastructre/Repositories/`.
8. Add repository to `I{Module}UnitOfWork` and implementation.
9. Create Commands/Queries in Application layer.

## 20. How to Add a Command

1. Create `{Action}{Entity}Command.cs` as a `sealed record : ICommand<TResponse>`.
2. Create `{Action}{Entity}CommandHandler.cs` implementing `ICommandHandler<TCommand, TResponse>`.
3. Create `{Action}{Entity}CommandValidator.cs` extending `AbstractValidator<TCommand>`.
4. Add endpoint in controller calling `_sender.Send(command)`.

## 21. How to Add a Query

1. Create `{QueryName}Query.cs` as a `sealed record : IQuery<TResponse>`.
2. Create `{QueryName}Response.cs` as a response DTO record.
3. Create `{QueryName}QueryHandler.cs` implementing `IQueryHandler<TQuery, TResponse>`.
4. Add endpoint in controller.
