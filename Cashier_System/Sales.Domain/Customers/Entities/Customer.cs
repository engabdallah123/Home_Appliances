using POS.Shared.Domain;

namespace Sales.Domain.Customers.Entities
{
    public sealed class Customer : Entity
    {
        public string Name { get; private set; } = default!;
        public string Phone { get; private set; } = default!;
        public string? Email { get; private set; }
        public string? Address { get; private set; }
        public int LoyaltyPoints { get; private set; }
        public decimal Balance { get; private set; }
        public bool IsActive { get; private set; }
        public DateTime CreatedAt { get; private set; }

        private Customer() { } // EF Core

        private Customer(Guid id, string name, string phone, string? email, string? address)
            : base(id)
        {
            Name = name;
            Phone = phone;
            Email = email;
            Address = address;
            LoyaltyPoints = 0;
            Balance = 0;
            IsActive = true;
            CreatedAt = DateTime.UtcNow;
        }

        public static Result<Customer> Create(string name, string phone, string? email = null, string? address = null)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result<Customer>.Failure(CustomerErrors.NameRequired);

            if (string.IsNullOrWhiteSpace(phone))
                return Result<Customer>.Failure(CustomerErrors.PhoneRequired);

            var customer = new Customer(Guid.NewGuid(), name.Trim(), phone.Trim(), email?.Trim(), address?.Trim());
            return Result<Customer>.Success(customer);
        }

        public Result Update(string name, string phone, string? email, string? address)
        {
            if (string.IsNullOrWhiteSpace(name))
                return Result.Failure(CustomerErrors.NameRequired);

            if (string.IsNullOrWhiteSpace(phone))
                return Result.Failure(CustomerErrors.PhoneRequired);

            Name = name.Trim();
            Phone = phone.Trim();
            Email = email?.Trim();
            Address = address?.Trim();
            return Result.Success();
        }

        public void AddLoyaltyPoints(int points) => LoyaltyPoints += points;
        public void AdjustBalance(decimal amount) => Balance += amount;
        public Result Activate() { IsActive = true; return Result.Success(); }
        public Result Deactivate() { IsActive = false; return Result.Success(); }
    }
}
