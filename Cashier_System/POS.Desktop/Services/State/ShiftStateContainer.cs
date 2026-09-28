namespace POS.Desktop.Services.State
{
    public class ShiftStateContainer
    {
        public bool IsShiftOpen { get; private set; }
        public Guid ShiftId { get; private set; }
        public DateTime StartTime { get; private set; }
        public decimal InitialCash { get; private set; }

        public event Action? OnShiftStateChanged;

        public void SetActiveShift(Guid shiftId, DateTime startTime, decimal initialCash)
        {
            ShiftId = shiftId;
            StartTime = startTime.Kind == DateTimeKind.Utc ? startTime.ToLocalTime() : startTime;
            InitialCash = initialCash;
            IsShiftOpen = true;
            NotifyStateChanged();
        }

        public void ClearShift()
        {
            ShiftId = Guid.Empty;
            IsShiftOpen = false;
            NotifyStateChanged();
        }

        private void NotifyStateChanged() => OnShiftStateChanged?.Invoke();
    }
}
