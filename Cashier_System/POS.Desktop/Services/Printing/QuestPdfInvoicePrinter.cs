using System.Net.Http;
using Microsoft.JSInterop;

namespace POS.Desktop.Services.Printing
{
    public class QuestPdfInvoicePrinter : IInvoicePrinterService
    {
        private readonly HttpClient _httpClient;
        private readonly IJSRuntime _jsRuntime;

        public QuestPdfInvoicePrinter(HttpClient httpClient, IJSRuntime jsRuntime)
        {
            _httpClient = httpClient;
            _jsRuntime = jsRuntime;
        }

        public async Task PrintInvoiceAsync(Guid saleId, bool isThermal = false)
        {
            var pdfBytes = await _httpClient.GetByteArrayAsync($"api/sales/{saleId}/pdf?isThermal={isThermal}");
            var base64 = Convert.ToBase64String(pdfBytes);
            await _jsRuntime.InvokeVoidAsync("printPdfFromBase64", base64);
        }
    }
}
