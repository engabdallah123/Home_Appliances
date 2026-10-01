using System.Windows;
using System.Windows.Input;

namespace POS.Desktop
{
    public partial class ExitAppConfirmationDialog : Window
    {
        public bool IsConfirmed { get; private set; } = false;

        public ExitAppConfirmationDialog(int cartItemsCount = 0)
        {
            InitializeComponent();

            if (cartItemsCount > 0)
            {
                PnlCartWarning.Visibility = Visibility.Visible;
                TxtCartWarning.Text = $"تنبيه: توجد ({cartItemsCount}) منتجات في سلة المبيعات لم يتم إتمام بيعها بعد!";
            }
            else
            {
                PnlCartWarning.Visibility = Visibility.Collapsed;
            }

            this.MouseLeftButtonDown += (s, e) =>
            {
                if (e.ButtonState == MouseButtonState.Pressed)
                {
                    try { DragMove(); } catch { }
                }
            };

            this.KeyDown += (s, e) =>
            {
                if (e.Key == Key.Escape)
                {
                    IsConfirmed = false;
                    Close();
                }
                else if (e.Key == Key.Enter)
                {
                    IsConfirmed = true;
                    Close();
                }
            };
        }

        private void OnConfirmExitClick(object sender, RoutedEventArgs e)
        {
            IsConfirmed = true;
            Close();
        }

        private void OnCancelClick(object sender, RoutedEventArgs e)
        {
            IsConfirmed = false;
            Close();
        }
    }
}
