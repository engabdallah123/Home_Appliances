using POS.Shared.Domain;

namespace Inventory.Domain.Stock.Warehouses
{
    public sealed class Warehouse : Entity
    {
        public string Name { get; private set; } = default!;
        public string Code { get; private set; } = default!;
        public string? Address { get; private set; }
        public bool IsActive { get; private set; }

        private Warehouse() { } // EF Core

        private Warehouse(Guid id, string name, string code, string? address)
            : base(id)
        {
            Name = name;
            Code = code;
            Address = address;
            IsActive = true;
        }

        public static Result<Warehouse> Create(string name, string code, string? address = null)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result<Warehouse>.Failure(WarehouseErrors.NameRequired);

            if (string.IsNullOrWhiteSpace(code))
                return Result<Warehouse>.Failure(WarehouseErrors.CodeRequired);

            var warehouse = new Warehouse(
                Guid.NewGuid(),
                name.Trim(),
                code.Trim().ToUpperInvariant(),
                string.IsNullOrWhiteSpace(address) ? null : address.Trim());

            return Result<Warehouse>.Success(warehouse);
        }

        public Result UpdateInfo(string name, string code, string? address)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(WarehouseErrors.NameRequired);

            if (string.IsNullOrWhiteSpace(code))
                return Result.Failure(WarehouseErrors.CodeRequired);

            Name = name.Trim();
            Code = code.Trim().ToUpperInvariant();
            Address = string.IsNullOrWhiteSpace(address) ? null : address.Trim();
            return Result.Success();
        }

        public Result Deactivate()
        {
            IsActive = false;
            return Result.Success();
        }

        public Result Activate()
        {
            IsActive = true;
            return Result.Success();
        }

        public Result Rename(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(WarehouseErrors.NameRequired);

            Name = name.Trim();
            return Result.Success();
        }
    }
}
