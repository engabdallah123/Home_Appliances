using MediatR;
using Microsoft.AspNetCore.Mvc;
using Purchases.Application.Purchases.Queries.GetSupplierDebts;
using Sales.Application.Sales.Queries.GetCustomerDebts;

namespace POS.WebAPI.Controllers.Debts
{
    [ApiController]
    [Route("api/debts")]
    public class DebtsController : ControllerBase
    {
        private readonly IMediator _sender;

        public DebtsController(IMediator sender)
        {
            _sender = sender;
        }

        [HttpGet("customers")]
        public async Task<IActionResult> GetCustomerDebts(
            [FromQuery] string? search = null,
            [FromQuery] Guid? customerId = null,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetCustomerDebtsQuery(search, customerId), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);
            return Ok(result.Value);
        }

        [HttpGet("suppliers")]
        public async Task<IActionResult> GetSupplierDebts(
            [FromQuery] string? search = null,
            [FromQuery] Guid? supplierId = null,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetSupplierDebtsQuery(search, supplierId), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);
            return Ok(result.Value);
        }
    }
}
