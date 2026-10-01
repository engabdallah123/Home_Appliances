using Sales.Domain.Installments.Entities;

namespace Sales.Application.Installments.DTOs
{
    public sealed class InstallmentScheduleDto
    {
        public Guid Id { get; set; }
        public Guid ContractId { get; set; }
        public int InstallmentNumber { get; set; }
        public DateTime DueDate { get; set; }
        public decimal Amount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public DateTime? PaidDate { get; set; }
        public InstallmentStatus Status { get; set; }
        public string StatusText { get; set; } = string.Empty;
        public string? PaymentMethod { get; set; }
        public string? Notes { get; set; }
    }

    public sealed class InstallmentContractDto
    {
        public Guid Id { get; set; }
        public string ContractNumber { get; set; } = string.Empty;
        public Guid SaleId { get; set; }
        public string InvoiceNumber { get; set; } = string.Empty;
        public Guid CustomerId { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string? GuarantorName { get; set; }
        public string? GuarantorPhone { get; set; }
        public string? GuarantorNationalId { get; set; }
        public string? GuarantorAddress { get; set; }
        public string? GuarantorNotes { get; set; }
        public decimal TotalCashAmount { get; set; }
        public decimal DownPayment { get; set; }
        public decimal InterestPercentage { get; set; }
        public decimal InterestAmount { get; set; }
        public decimal TotalInstallmentAmount { get; set; }
        public decimal MonthlyInstallmentAmount { get; set; }
        public decimal TotalPaidAmount { get; set; }
        public decimal RemainingBalance { get; set; }
        public int NumberOfMonths { get; set; }
        public DateTime StartDate { get; set; }
        public InstallmentContractStatus Status { get; set; }
        public string StatusText { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<InstallmentScheduleDto> Schedules { get; set; } = new();
    }

    public sealed class UpcomingInstallmentAlertDto
    {
        public Guid ScheduleId { get; set; }
        public Guid ContractId { get; set; }
        public string ContractNumber { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string? GuarantorName { get; set; }
        public string? GuarantorPhone { get; set; }
        public int InstallmentNumber { get; set; }
        public DateTime DueDate { get; set; }
        public decimal Amount { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal RemainingAmount { get; set; }
        public bool IsOverdue { get; set; }
        public int DaysOverdueOrRemaining { get; set; }
    }
}
