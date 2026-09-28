namespace POS.Desktop.Services.Printing
{
    public interface IInvoicePrinterService
    {
        Task PrintInvoiceAsync(Guid saleId, bool isThermal = false);
    }
}
