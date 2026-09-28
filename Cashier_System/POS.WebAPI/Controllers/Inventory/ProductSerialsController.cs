using Inventory.Application.Catalog.Products.Commands.AddProductSerials;
using Inventory.Application.Catalog.Products.Queries.GetProductSerials;
using Inventory.Application.Catalog.Products.Queries.VerifyProductSerial;
using Inventory.Domain.Catalog.Products.Entities;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace POS.WebAPI.Controllers.Inventory
{
    [ApiController]
    [Route("api/inventory/serials")]
    [Authorize]
    public class ProductSerialsController : ControllerBase
    {
        private readonly IMediator _sender;

        public ProductSerialsController(IMediator sender)
        {
            _sender = sender;
        }

        [HttpGet("product/{productId:guid}")]
        public async Task<IActionResult> GetByProduct(Guid productId, [FromQuery] ProductSerialStatus? status = null, CancellationToken ct = default)
        {
            var result = await _sender.Send(new GetProductSerialsQuery(productId, status), ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(result.Value);
        }

        [HttpGet("verify/{serialNumber}")]
        public async Task<IActionResult> Verify(string serialNumber, [FromQuery] Guid? productId = null, CancellationToken ct = default)
        {
            var result = await _sender.Send(new VerifyProductSerialQuery(serialNumber, productId), ct);
            if (result.IsFailure)
                return NotFound(result.Error);

            return Ok(result.Value);
        }

        [HttpPost]
        [Authorize(Roles = "Admin,Manager,Cashier,Administrator")]
        public async Task<IActionResult> AddSerials([FromBody] AddProductSerialsCommand command, CancellationToken ct)
        {
            var result = await _sender.Send(command, ct);
            if (result.IsFailure)
                return BadRequest(result.Error);

            return Ok(new { addedCount = result.Value });
        }
    }
}
