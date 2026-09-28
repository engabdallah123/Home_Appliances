using Identity.Application.Services;
using Identity.Domain.Users;
using Identity.Domain.Users.Entities;
using Microsoft.AspNetCore.Identity;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Identity.Application.Auth.Commands.RefreshToken
{
    internal sealed class RefreshTokenCommandHandler : ICommandHandler<RefreshTokenCommand, AuthResponse>
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IJwtTokenService _jwtTokenService;

        public RefreshTokenCommandHandler(
            UserManager<ApplicationUser> userManager,
            IJwtTokenService jwtTokenService)
        {
            _userManager = userManager;
            _jwtTokenService = jwtTokenService;
        }

        public async Task<Result<AuthResponse>> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
        {
            // البحث عن المستخدم بالـ Refresh Token
            var users = _userManager.Users
                .Where(u => u.RefreshToken == request.RefreshToken)
                .ToList();

            var user = users.FirstOrDefault();
            if (user is null || user.RefreshTokenExpiry <= DateTime.UtcNow)
                return Result<AuthResponse>.Failure(UserErrors.InvalidRefreshToken);

            if (!user.IsActive)
                return Result<AuthResponse>.Failure(UserErrors.UserInactive);

            var roles = await _userManager.GetRolesAsync(user);
            var newAccessToken = _jwtTokenService.GenerateAccessToken(user, roles);
            var newRefreshToken = _jwtTokenService.GenerateRefreshToken();

            user.RefreshToken = newRefreshToken;
            user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
            await _userManager.UpdateAsync(user);

            return Result<AuthResponse>.Success(new AuthResponse(
                newAccessToken,
                newRefreshToken,
                DateTime.UtcNow.AddHours(1),
                user.Id,
                user.FullName,
                roles.FirstOrDefault() ?? "Cashier"));
        }
    }
}
