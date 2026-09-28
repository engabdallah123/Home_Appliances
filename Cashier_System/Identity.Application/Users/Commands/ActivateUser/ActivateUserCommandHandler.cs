using Identity.Domain.Users;
using Identity.Domain.Users.Entities;
using Microsoft.AspNetCore.Identity;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Identity.Application.Users.Commands.ActivateUser
{
    internal sealed class ActivateUserCommandHandler : ICommandHandler<ActivateUserCommand>
    {
        private readonly UserManager<ApplicationUser> _userManager;

        public ActivateUserCommandHandler(UserManager<ApplicationUser> userManager)
        {
            _userManager = userManager;
        }

        public async Task<Result> Handle(ActivateUserCommand request, CancellationToken cancellationToken)
        {
            var user = await _userManager.FindByIdAsync(request.Id);
            if (user is null)
                return Result.Failure(UserErrors.NotFound(request.Id));

            user.IsActive = true;
            await _userManager.UpdateAsync(user);
            return Result.Success();
        }
    }
}
