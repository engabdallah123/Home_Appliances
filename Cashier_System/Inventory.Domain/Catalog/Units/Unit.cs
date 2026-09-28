using POS.Shared.Domain;

namespace Inventory.Domain.Catalog.Units
{
    public sealed class Unit : Entity
    {
        public string NameAr { get; private set; } = default!;
        public string NameEn { get; private set; } = default!;
        public string Symbol { get; private set; } = default!;

        private Unit() { } // EF Core

        private Unit(Guid id, string nameAr, string nameEn, string symbol)
            : base(id)
        {
            NameAr = nameAr;
            NameEn = nameEn;
            Symbol = symbol;
        }

        public static Result<Unit> Create(string nameAr, string nameEn, string symbol)
        {
            if (string.IsNullOrWhiteSpace(nameAr))
                return Result<Unit>.Failure(UnitErrors.NameArRequired);

            if (string.IsNullOrWhiteSpace(nameEn))
                return Result<Unit>.Failure(UnitErrors.NameEnRequired);

            if (string.IsNullOrWhiteSpace(symbol))
                return Result<Unit>.Failure(UnitErrors.SymbolRequired);

            var unit = new Unit(Guid.NewGuid(), nameAr.Trim(), nameEn.Trim(), symbol.Trim());
            return Result<Unit>.Success(unit);
        }

        public Result Update(string nameAr, string nameEn, string symbol)
        {
            if (string.IsNullOrWhiteSpace(nameAr))
                return Result.Failure(UnitErrors.NameArRequired);

            if (string.IsNullOrWhiteSpace(nameEn))
                return Result.Failure(UnitErrors.NameEnRequired);

            if (string.IsNullOrWhiteSpace(symbol))
                return Result.Failure(UnitErrors.SymbolRequired);

            NameAr = nameAr.Trim();
            NameEn = nameEn.Trim();
            Symbol = symbol.Trim();
            return Result.Success();
        }
    }
}
