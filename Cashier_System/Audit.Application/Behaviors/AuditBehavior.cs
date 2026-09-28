using System.Text.Json;
using Audit.Domain;
using Audit.Domain.AuditLogs.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Audit.Application.Behaviors;

public class AuditBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IBaseCommand
    where TResponse : Result
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<AuditBehavior<TRequest, TResponse>> _logger;

    public AuditBehavior(
        IServiceProvider serviceProvider,
        IHttpContextAccessor httpContextAccessor,
        ILogger<AuditBehavior<TRequest, TResponse>> logger)
    {
        _serviceProvider = serviceProvider;
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var response = await next();

        var requestName = request.GetType().Name;
        if (response.IsSuccess && requestName != "CreateAuditLogCommand")
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var unitOfWork = scope.ServiceProvider.GetService<IAuditUnitOfWork>();

                if (unitOfWork != null)
                {
                    var entityName = ExtractEntityName(requestName);
                    var userId = GetCurrentUserId();
                    var ipAddress = _httpContextAccessor.HttpContext?.Connection.RemoteIpAddress?.ToString();
                    var newValues = JsonSerializer.Serialize(request, request.GetType());

                    var logResult = AuditLog.Create(
                        userId: userId,
                        action: requestName,
                        entityName: entityName,
                        entityId: ExtractEntityId(request, response),
                        oldValues: null,
                        newValues: newValues,
                        ipAddress: ipAddress);

                    if (logResult.IsSuccess)
                    {
                        await unitOfWork.AuditLogRepository.AddAsync(logResult.Value!);
                        await unitOfWork.SaveChangesAsync(cancellationToken);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to record audit log for command {RequestName}", requestName);
            }
        }

        return response;
    }

    private static string ExtractEntityName(string requestName)
    {
        var name = requestName.Replace("Command", "");
        foreach (var action in new[] { "Create", "Update", "Delete", "Open", "Close", "Receive", "Pay", "Cancel" })
        {
            if (name.StartsWith(action))
            {
                name = name[action.Length..];
                break;
            }
        }
        return string.IsNullOrWhiteSpace(name) ? requestName : name;
    }

    private static Guid? ExtractEntityId(TRequest request, TResponse response)
    {
        var responseType = response.GetType();
        var valueProp = responseType.GetProperty("Value");
        if (valueProp != null)
        {
            var val = valueProp.GetValue(response);
            if (val is Guid guidVal) return guidVal;
        }

        var requestType = request.GetType();
        var idProp = requestType.GetProperty("Id")
            ?? requestType.GetProperty("EntityId")
            ?? requestType.GetProperty("ProductId")
            ?? requestType.GetProperty("PurchaseId")
            ?? requestType.GetProperty("ShiftId");

        if (idProp != null)
        {
            var val = idProp.GetValue(request);
            if (val is Guid guidVal) return guidVal;
        }

        return null;
    }

    private Guid? GetCurrentUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        var claim = user?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)
            ?? user?.FindFirst("sub")
            ?? user?.FindFirst("uid");

        if (claim != null && Guid.TryParse(claim.Value, out var userId))
        {
            return userId;
        }
        return null;
    }
}
