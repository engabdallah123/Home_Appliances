using Identity.Domain.Users.Entities;

namespace Identity.Application.Services
{
    public interface IJwtTokenService
    {
        string GenerateAccessToken(ApplicationUser user, IList<string> roles);
        string GenerateRefreshToken();
    }
}
