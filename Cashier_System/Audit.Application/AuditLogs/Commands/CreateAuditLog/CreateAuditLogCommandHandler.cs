using Audit.Domain;
using Audit.Domain.AuditLogs.Entities;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Audit.Application.AuditLogs.Commands.CreateAuditLog
{
    internal sealed class CreateAuditLogCommandHandler : ICommandHandler<CreateAuditLogCommand, Guid>
    {
        private readonly IAuditUnitOfWork _unitOfWork;

        public CreateAuditLogCommandHandler(IAuditUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateAuditLogCommand request, CancellationToken cancellationToken)
        {
            var logResult = AuditLog.Create(
                request.UserId, request.Action, request.EntityName,
                request.EntityId, request.OldValues, request.NewValues,
                request.IpAddress);

            if (logResult.IsFailure)
                return Result<Guid>.Failure(logResult.Error);

            var log = logResult.Value!;

            await _unitOfWork.AuditLogRepository.AddAsync(log);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<Guid>.Success(log.Id);
        }
    }
}
