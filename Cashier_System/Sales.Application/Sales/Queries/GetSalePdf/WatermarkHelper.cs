using SkiaSharp;

namespace Sales.Application.Sales.Queries.GetSalePdf
{
    public static class WatermarkHelper
    {
        /// <summary>
        /// Applies an ultra-light, subtle watermark transparency (e.g. 5% - 7% opacity)
        /// so that background text and numbers remain 100% crisp and readable.
        /// </summary>
        public static byte[] MakeFaintWatermark(byte[]? originalBytes, float opacity = 0.15f)
        {
            if (originalBytes == null || originalBytes.Length == 0)
                return originalBytes ?? Array.Empty<byte>();

            try
            {
                using var originalBitmap = SKBitmap.Decode(originalBytes);
                if (originalBitmap == null)
                    return originalBytes;

                var imageInfo = new SKImageInfo(originalBitmap.Width, originalBitmap.Height, SKColorType.Rgba8888, SKAlphaType.Premul);
                using var surface = SKSurface.Create(imageInfo);
                if (surface == null) return originalBytes;

                var canvas = surface.Canvas;
                canvas.Clear(SKColors.Transparent);

                // Alpha modulation to reduce opacity to subtle watermark level
                byte alpha = (byte)Math.Clamp((int)(opacity * 255), 20, 255);
                using var paint = new SKPaint
                {
                    Color = new SKColor(255, 255, 255, alpha),
                    ColorFilter = SKColorFilter.CreateBlendMode(new SKColor(255, 255, 255, alpha), SKBlendMode.Modulate),
                    IsAntialias = true,
                    FilterQuality = SKFilterQuality.High
                };

                canvas.DrawBitmap(originalBitmap, 0, 0, paint);
                canvas.Flush();

                using var snapshot = surface.Snapshot();
                using var data = snapshot.Encode(SKEncodedImageFormat.Png, 100);
                return data.ToArray();
            }
            catch
            {
                return originalBytes;
            }
        }
    }
}
