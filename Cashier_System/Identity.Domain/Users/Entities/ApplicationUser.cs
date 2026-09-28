using Microsoft.AspNetCore.Identity;

namespace Identity.Domain.Users.Entities
{
    public sealed class ApplicationUser : IdentityUser
    {
        public string FullName { get; set; } = default!;
        public string? Phone { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string? RefreshToken { get; set; }
        public DateTime? RefreshTokenExpiry { get; set; }
    }
}
