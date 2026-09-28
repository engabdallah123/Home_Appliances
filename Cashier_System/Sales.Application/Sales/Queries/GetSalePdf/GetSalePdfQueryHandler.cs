using MediatR;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using QuestPDF.Fluent;
using QuestPDF.Infrastructure;
using Sales.Application.Sales.Queries.GetSaleReceipt;

namespace Sales.Application.Sales.Queries.GetSalePdf
{
    internal sealed class GetSalePdfQueryHandler : IQueryHandler<GetSalePdfQuery, byte[]>
    {
        private readonly ISender _sender;

        public GetSalePdfQueryHandler(ISender sender)
        {
            _sender = sender;
        }

        public async Task<Result<byte[]>> Handle(GetSalePdfQuery request, CancellationToken cancellationToken)
        {
            // Configure QuestPDF license to Community
            QuestPDF.Settings.License = LicenseType.Community;

            var receiptResult = await _sender.Send(new GetSaleReceiptQuery(request.SaleId), cancellationToken);
            if (receiptResult.IsFailure)
                return Result<byte[]>.Failure(receiptResult.Error);

            var document = new InvoicePdfDocument(receiptResult.Value!, request.IsThermal);
            var pdfBytes = document.GeneratePdf();

            return Result<byte[]>.Success(pdfBytes);
        }
    }
}
