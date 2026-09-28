using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sales.Application.Installments.Commands.PayInstallmentSchedule;
using Sales.Application.Installments.Queries.GetInstallmentContractById;
using Sales.Application.Installments.Queries.GetInstallmentContracts;
using Sales.Application.Installments.Queries.GetUpcomingInstallments;
using Sales.Domain.Installments.Entities;

namespace POS.WebAPI.Controllers.Sales
{
    [ApiController]
    [Route("api/sales/installments")]
    [Authorize]
    public class InstallmentsController : ControllerBase
    {
        private readonly IMediator _sender;

        public InstallmentsController(IMediator sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] Guid? customerId = null,
            [FromQuery] InstallmentContractStatus? status = null,
            [FromQuery] string? search = null,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetInstallmentContractsQuery(customerId, status, search), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id, CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetInstallmentContractByIdQuery(id), ct);
            if (result.IsFailure)
                return NotFound(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("upcoming")]
        public async Task<IActionResult> GetUpcoming([FromQuery] int daysAhead = 30, CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetUpcomingInstallmentsQuery(daysAhead), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }

        [HttpPost("pay")]
        [Authorize(Roles = "Admin,Manager,Cashier,Administrator")]
        public async Task<IActionResult> PayInstallment([FromBody] PayInstallmentScheduleCommand command, CancellationToken ct = default)
        {
            var result = await _sender.Send(command, ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(new { message = "تم تسجيل سداد القسط بنجاح" });
        }
    }
}
