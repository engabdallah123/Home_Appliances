using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sales.Application.Promotions.Commands.CreateOffer;
using Sales.Application.Promotions.Commands.DeleteOffer;
using Sales.Application.Promotions.Commands.ToggleOfferStatus;
using Sales.Application.Promotions.DTOs;
using Sales.Application.Promotions.Queries.GetOffers;
using Sales.Domain.Promotions.Entities;

namespace POS.WebAPI.Controllers.Sales
{
    [ApiController]
    [Route("api/sales/offers")]
    [Authorize]
    public class OffersController : ControllerBase
    {
        private readonly IMediator _sender;

        public OffersController(IMediator sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] bool? onlyActive = null,
            [FromQuery] OfferType? type = null,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetOffersQuery(onlyActive, type), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("active")]
        public async Task<IActionResult> GetActive(
            [FromQuery] OfferType? type = null,
            CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetOffersQuery(OnlyActive: true, Type: type), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            // Filter only valid dates
            var validOffers = result.Value?.Where(o => o.IsCurrentlyValid).ToList() ?? new List<OfferDto>();
            return Ok(validOffers);
        }

        [HttpPost]
        [Authorize(Roles = "Admin,Manager,Administrator")]
        public async Task<IActionResult> Create([FromBody] CreateOfferCommand command, CancellationToken ct = default)
        {
            var result = await _sender.Send(command, ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(new { id = result.Value });
        }

        [HttpPatch("{id:guid}/toggle")]
        [Authorize(Roles = "Admin,Manager,Administrator")]
        public async Task<IActionResult> ToggleStatus(Guid id, CancellationToken ct = default)
        {
            var result = await _sender.Send(new ToggleOfferStatusCommand(id), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return NoContent();
        }

        [HttpDelete("{id:guid}")]
        [Authorize(Roles = "Admin,Manager,Administrator")]
        public async Task<IActionResult> Delete(Guid id, CancellationToken ct = default)
        {
            var result = await _sender.Send(new DeleteOfferCommand(id), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return NoContent();
        }
    }
}
