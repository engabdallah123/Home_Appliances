using SkiaSharp;

namespace Sales.Application.Sales.Queries.GetSalePdf
{
    public static class WatermarkHelper
    {
        /// <summary>
        /// Converts the store logo into a clear, elegant background watermark.
        /// Applies balanced linear transparency (~20% - 25% opacity) so the watermark is clearly visible,
        /// while ensuring that foreground invoice text, numbers, and grid lines remain 100% crisp and readable.
        /// </summary>
        public static byte[] MakeFaintWatermark(byte[]? originalBytes, float opacity = 0.22f)
        {
            if (originalBytes == null || originalBytes.Length == 0)
                return originalBytes ?? Array.Empty<byte>();

            try
            {
                using var originalBitmap = SKBitmap.Decode(originalBytes);
                if (originalBitmap == null)
                    return originalBytes;

                int width = originalBitmap.Width;
                int height = originalBitmap.Height;

                // Create a 32-bit RGBA surface with premultiplied alpha
                var imageInfo = new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul);
                using var surface = SKSurface.Create(imageInfo);
                if (surface == null) return originalBytes;

                var canvas = surface.Canvas;
                canvas.Clear(SKColors.Transparent);

                // Target opacity ratio (e.g. 0.22 = 22% opacity)
                float alphaScale = Math.Clamp(opacity, 0.15f, 0.35f);

                // Use ColorMatrix: scales alpha channel directly and linearly without multiplying twice or darkening colors
                // [ 1  0  0  0          0 ]
                // [ 0  1  0  0          0 ]
                // [ 0  0  1  0          0 ]
                // [ 0  0  0  alphaScale 0 ]
                float[] colorMatrix = new float[]
                {
                    1.0f, 0.0f, 0.0f, 0.0f, 0.0f,
                    0.0f, 1.0f, 0.0f, 0.0f, 0.0f,
                    0.0f, 0.0f, 1.0f, 0.0f, 0.0f,
                    0.0f, 0.0f, 0.0f, alphaScale, 0.0f
                };

                using var colorFilter = SKColorFilter.CreateColorMatrix(colorMatrix);
                using var paint = new SKPaint
                {
                    ColorFilter = colorFilter,
                    IsAntialias = true,
                    FilterQuality = SKFilterQuality.High
                };

                // Draw the bitmap with the alpha-scaling color filter
                canvas.DrawBitmap(originalBitmap, 0, 0, paint);
                canvas.Flush();

                using var snapshot = surface.Snapshot();
                using var data = snapshot.Encode(SKEncodedImageFormat.Png, 100);
                if (data != null && data.Size > 0)
                {
                    return data.ToArray();
                }

                return originalBytes;
            }
            catch
            {
                return originalBytes;
            }
        }

        /// <summary>
        /// Trims empty (transparent or near-white) borders around an image so that headers and footers
        /// fit edge-to-edge properly without unnecessary whitespace padding.
        /// </summary>
        public static byte[] TrimWhitespace(byte[]? originalBytes, byte whiteThreshold = 245)
        {
            if (originalBytes == null || originalBytes.Length == 0)
                return originalBytes ?? Array.Empty<byte>();

            try
            {
                using var bmp = SKBitmap.Decode(originalBytes);
                if (bmp == null)
                    return originalBytes;

                int width = bmp.Width;
                int height = bmp.Height;
                int minX = width, maxX = -1, minY = height, maxY = -1;

                for (int y = 0; y < height; y++)
                {
                    for (int x = 0; x < width; x++)
                    {
                        var color = bmp.GetPixel(x, y);
                        bool isBackground = color.Alpha < 15 ||
                            (color.Red >= whiteThreshold && color.Green >= whiteThreshold && color.Blue >= whiteThreshold);
                        if (!isBackground)
                        {
                            if (x < minX) minX = x;
                            if (x > maxX) maxX = x;
                            if (y < minY) minY = y;
                            if (y > maxY) maxY = y;
                        }
                    }
                }

                if (minX > maxX || minY > maxY)
                    return originalBytes;

                int cropWidth = maxX - minX + 1;
                int cropHeight = maxY - minY + 1;

                // If already >= 98% of original in both dimensions, avoid re-encoding
                if (cropWidth >= width * 0.98f && cropHeight >= height * 0.98f)
                    return originalBytes;

                var imageInfo = new SKImageInfo(cropWidth, cropHeight, bmp.ColorType, bmp.AlphaType);
                using var surface = SKSurface.Create(imageInfo);
                if (surface == null) return originalBytes;

                var canvas = surface.Canvas;
                canvas.Clear(SKColors.Transparent);

                var srcRect = new SKRect(minX, minY, maxX + 1, maxY + 1);
                var destRect = new SKRect(0, 0, cropWidth, cropHeight);
                using var paint = new SKPaint
                {
                    IsAntialias = true,
                    FilterQuality = SKFilterQuality.High
                };

                canvas.DrawBitmap(bmp, srcRect, destRect, paint);
                canvas.Flush();

                using var snapshot = surface.Snapshot();
                using var data = snapshot.Encode(SKEncodedImageFormat.Png, 100);
                return (data != null && data.Size > 0) ? data.ToArray() : originalBytes;
            }
            catch
            {
                return originalBytes;
            }
        }
    }
}
