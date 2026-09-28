using POS.Shared.Application.Messaging;

namespace Settings.Application.StoreSettings.Queries.GetSettings
{
    public sealed record GetSettingsQuery() : IQuery<StoreSettingResponse>;
}
