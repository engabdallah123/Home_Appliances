using POS.Shared.Application.Messaging;

namespace Dashboard.Application.Dashboard.Queries.GetDashboard
{
    public sealed record GetDashboardQuery(
        DateTime? FromDate = null,
        DateTime? ToDate = null) : IQuery<DashboardResponse>;
}
