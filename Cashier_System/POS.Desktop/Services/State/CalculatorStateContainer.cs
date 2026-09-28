namespace POS.Desktop.Services.State
{
    public class CalculatorStateContainer
    {
        public bool IsOpen { get; private set; }

        public event Action? OnStateChanged;

        public void Open()
        {
            if (!IsOpen)
            {
                IsOpen = true;
                NotifyStateChanged();
            }
        }

        public void Close()
        {
            if (IsOpen)
            {
                IsOpen = false;
                NotifyStateChanged();
            }
        }

        public void Toggle()
        {
            IsOpen = !IsOpen;
            NotifyStateChanged();
        }

        private void NotifyStateChanged() => OnStateChanged?.Invoke();
    }
}
