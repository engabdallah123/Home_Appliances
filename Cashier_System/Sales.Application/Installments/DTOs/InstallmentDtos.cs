using Sales.Domain.Installments.Entities;

namespace Sales.Application.Installments.DTOs
{
    public sealed record InstallmentScheduleDto(
        Guid Id,
        Guid ContractId,
        int InstallmentNumber,
        DateTime DueDate,
        decimal Amount,
        decimal PaidAmount,
        decimal RemainingAmount,
        DateTime? PaidDate,
        InstallmentStatus Status,
        string StatusText,
        string? PaymentMethod,
        string? Notes);

    public sealed record InstallmentContractDto(
        Guid Id,
        string ContractNumber,
        Guid SaleId,
        string InvoiceNumber,
        Guid CustomerId,
        string CustomerName,
        string CustomerPhone,
        string GuarantorName,
        string GuarantorPhone,
        string? GuarantorNationalId,
        string? GuarantorAddress,
        string? GuarantorNotes,
        decimal TotalCashAmount,
        decimal DownPayment,
        decimal InterestPercentage,
        decimal InterestAmount,
        decimal TotalInstallmentAmount,
        decimal MonthlyInstallmentAmount,
        decimal TotalPaidAmount,
        decimal RemainingBalance,
        int NumberOfMonths,
        DateTime StartDate,
        InstallmentContractStatus Status,
        string StatusText,
        string? Notes,
        DateTime CreatedAt,
        List<InstallmentScheduleDto>? Schedules = null);

    public sealed record UpcomingInstallmentAlertDto(
        Guid ScheduleId,
        Guid ContractId,
        string ContractNumber,
        string CustomerName,
        string CustomerPhone,
        string GuarantorName,
        string GuarantorPhone,
        int InstallmentNumber,
        DateTime DueDate,
        decimal Amount,
        decimal PaidAmount,
        decimal RemainingAmount,
        bool IsOverdue,
        int DaysOverdueOrRemaining);
}
