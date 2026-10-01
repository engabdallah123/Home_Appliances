using Microsoft.AspNetCore.Components.WebView.Wpf;
using System.Windows;

namespace POS.Desktop
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            blazorWebView.Services = App.Services;
            blazorWebView.RootComponents.Add(new RootComponent
            {
                Selector = "#app",
                ComponentType = typeof(AppRoutes)
            });

            blazorWebView.BlazorWebViewInitialized += (sender, e) =>
            {
                if (blazorWebView.WebView?.CoreWebView2?.Settings != null)
                {
                    // Disable built-in Chromium browser shortcut keys (Ctrl+P print, Ctrl+S save, Ctrl+F find, etc.)
                    blazorWebView.WebView.CoreWebView2.Settings.AreBrowserAcceleratorKeysEnabled = false;
                }
            };

            this.Closing += MainWindow_Closing;
        }

        private void MainWindow_Closing(object? sender, System.ComponentModel.CancelEventArgs e)
        {
            try
            {
                var draftContainer = App.Services?.GetService(typeof(POS.Desktop.Services.State.PurchaseDraftStateContainer)) 
                    as POS.Desktop.Services.State.PurchaseDraftStateContainer;

                if (draftContainer != null && draftContainer.HasDraft)
                {
                    var dialog = new DraftExitDialog(draftContainer.ItemsCount, draftContainer.TotalAmount)
                    {
                        Owner = this
                    };
                    dialog.ShowDialog();

                    switch (dialog.ResultChoice)
                    {
                        case DraftExitChoice.SaveAndExit:
                            draftContainer.SaveToDisk();
                            e.Cancel = false;
                            break;

                        case DraftExitChoice.DiscardAndExit:
                            draftContainer.ClearDraft();
                            e.Cancel = false;
                            break;

                        case DraftExitChoice.Cancel:
                        default:
                            e.Cancel = true;
                            break;
                    }
                    return;
                }

                var cartContainer = App.Services?.GetService(typeof(POS.Desktop.Services.State.CartStateContainer))
                    as POS.Desktop.Services.State.CartStateContainer;

                int cartCount = (cartContainer != null && cartContainer.Items.Any()) ? cartContainer.Items.Count : 0;

                // Modern Exit Confirmation Dialog
                var exitDialog = new ExitAppConfirmationDialog(cartCount)
                {
                    Owner = this
                };
                exitDialog.ShowDialog();

                if (!exitDialog.IsConfirmed)
                {
                    e.Cancel = true;
                }
            }
            catch
            {
                // In case of any unexpected dialog exception, do not crash the app
            }
        }
    }
}
