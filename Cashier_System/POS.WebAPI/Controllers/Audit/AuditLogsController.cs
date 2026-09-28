using Audit.Application.AuditLogs.Queries.GetAuditLogById;
using Audit.Application.AuditLogs.Queries.GetAuditLogs;
using Audit.Application.AuditLogs.Queries.GetAuditLogsByUserId;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace POS.WebAPI.Controllers.Audit
{
    [ApiController]
    [Route("api/audit-logs")]
    public class AuditLogsController : ControllerBase
    {
        private readonly IMediator _sender;

        public AuditLogsController(IMediator sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50,
            [FromQuery] string? entityName = null,
            [FromQuery] string? action = null,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(
                new GetAuditLogsQuery(page, pageSize, entityName, action), ct);

            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
        {
            var result = await _sender.Send(new GetAuditLogByIdQuery(id), ct);
            if (result.IsFailure)
                return NotFound(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("user/{userId:guid}")]
        public async Task<IActionResult> GetByUserId(
            Guid userId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(
                new GetAuditLogsByUserIdQuery(userId, page, pageSize), ct);

            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }
    }
}
