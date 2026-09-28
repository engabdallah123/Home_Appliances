using MediatR;
using Microsoft.AspNetCore.Mvc;
using Shifts.Application.Shifts.Commands.CloseShift;
using Shifts.Application.Shifts.Commands.OpenShift;
using Shifts.Application.Shifts.Queries.GetCurrentShift;
using Shifts.Application.Shifts.Queries.GetShiftById;
using Shifts.Application.Shifts.Queries.GetShifts;
using Shifts.Application.Shifts.Queries.GetShiftSummary;

namespace POS.WebAPI.Controllers.Shifts
{
    [ApiController]
    [Route("api/[controller]")]
    public class ShiftsController : ControllerBase
    {
        private readonly IMediator _sender;

        public ShiftsController(IMediator sender)
        {
            _sender = sender;
        }

        [HttpPost("open")]
        public async Task<IActionResult> Open([FromBody] OpenShiftCommand command, CancellationToken ct)
        {
            var result = await _sender.Send(command, ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return CreatedAtAction(nameof(GetById), new { id = result.Value }, result.Value);
        }

        [HttpPost("{id:guid}/close")]
        public async Task<IActionResult> Close(Guid id, [FromBody] CloseShiftCommand command, CancellationToken ct)
        {
            if (id != command.ShiftId)
                return BadRequest("ID in URL does not match request body.");

            var result = await _sender.Send(command, ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return NoContent();
        }

        [HttpGet("current/{cashierId:guid}")]
        public async Task<IActionResult> GetCurrent(Guid cashierId, CancellationToken ct)
        {
            var result = await _sender.Send(new GetCurrentShiftQuery(cashierId), ct);
            if (result.IsFailure)
                return NotFound(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
        {
            var result = await _sender.Send(new GetShiftByIdQuery(id), ct);
            if (result.IsFailure)
                return NotFound(result.Error);

            return Ok(result.Value);
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] Guid? cashierId = null,
            [FromQuery] DateTime? fromDate = null,
            [FromQuery] DateTime? toDate = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetShiftsQuery(cashierId, fromDate, toDate, page, pageSize), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("{id:guid}/summary")]
        public async Task<IActionResult> GetSummary(Guid id, CancellationToken ct)
        {
            var result = await _sender.Send(new GetShiftSummaryQuery(id), ct);
            if (result.IsFailure)
                return NotFound(result.Error);

            return Ok(result.Value);
        }
    }
}
