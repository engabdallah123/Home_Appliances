using Amazon.S3;
using Amazon.S3.Model;
using System.IO;
using System.IO.Compression;
using System.Text.Json;

namespace POS.Desktop.Services.Backup
{
    public class CloudflareR2Settings
    {
        public bool IsEnabled { get; set; } = false;
        public string AccountId { get; set; } = string.Empty;
        public string AccessKeyId { get; set; } = string.Empty;
        public string SecretAccessKey { get; set; } = string.Empty;
        public string BucketName { get; set; } = string.Empty;
        public int LocalRetentionCount { get; set; } = 5;
        public bool AutoUploadOnBackup { get; set; } = true;
        public string LastUploadedBackupFileName { get; set; } = string.Empty;
        public DateTime? LastUploadedAtUtc { get; set; }
    }

    public class CloudBackupItem
    {
        public string Key { get; set; } = string.Empty;
        public long Size { get; set; }
        public DateTime LastModified { get; set; }
    }

    public interface ICloudflareR2BackupService
    {
        CloudflareR2Settings GetSettings();
        Task SaveSettingsAsync(CloudflareR2Settings settings);
        (byte[] ZipBytes, string ZipFileName) CompressJsonBytes(byte[] jsonBytes, string originalFileName);
        Task<string> ExtractJsonFromBackupAsync(string filePath);
        (int DeletedCount, long FreedBytes) PruneLocalBackups(string folderPath, int maxToKeep = 5);
        Task<(bool Success, string? ErrorMessage)> TestConnectionAsync(CloudflareR2Settings settings);
        Task<(bool Success, string? ErrorMessage, string? RemoteKey)> UploadBackupAsync(string filePath, CloudflareR2Settings settings);
        Task<(bool Success, List<CloudBackupItem> Items, string? ErrorMessage)> ListCloudBackupsAsync(CloudflareR2Settings settings);
        Task<(bool Success, string? ErrorMessage)> DeleteCloudBackupAsync(string key, CloudflareR2Settings settings);
        Task CheckAndUploadLatestBackupSilentlyAsync();
    }

    public class CloudflareR2BackupService : ICloudflareR2BackupService, IDisposable
    {
        private static readonly string SettingsFilePath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "ElectroPOS",
            "r2_backup_config.json"
        );

        private CloudflareR2Settings _cachedSettings = new();
        private readonly SemaphoreSlim _uploadLock = new(1, 1);
        private FileSystemWatcher? _folderWatcher;
        private Timer? _backgroundScanTimer;
        private bool _isDisposed;

        public CloudflareR2BackupService()
        {
            LoadSettings();
            StartBackgroundWatcher();
        }

        private void LoadSettings()
        {
            try
            {
                if (File.Exists(SettingsFilePath))
                {
                    var json = File.ReadAllText(SettingsFilePath);
                    var settings = JsonSerializer.Deserialize<CloudflareR2Settings>(json);
                    if (settings != null)
                    {
                        _cachedSettings = settings;
                        return;
                    }
                }
            }
            catch { }

            _cachedSettings = new CloudflareR2Settings();
        }

        public CloudflareR2Settings GetSettings()
        {
            return _cachedSettings;
        }

        public async Task SaveSettingsAsync(CloudflareR2Settings settings)
        {
            _cachedSettings = settings ?? new CloudflareR2Settings();
            try
            {
                var dir = Path.GetDirectoryName(SettingsFilePath);
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }

                var json = JsonSerializer.Serialize(_cachedSettings, new JsonSerializerOptions { WriteIndented = true });
                await File.WriteAllTextAsync(SettingsFilePath, json);
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"فشل حفظ إعدادات Cloudflare R2: {ex.Message}", ex);
            }
        }

        private void StartBackgroundWatcher()
        {
            try
            {
                var defaultFolder = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
                    "POS_Cashier_Backups");

                if (!Directory.Exists(defaultFolder))
                {
                    Directory.CreateDirectory(defaultFolder);
                }

                _folderWatcher = new FileSystemWatcher(defaultFolder)
                {
                    Filter = "POS_Backup_*.*",
                    NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite | NotifyFilters.Size,
                    EnableRaisingEvents = true
                };

                _folderWatcher.Created += OnNewBackupFileCreated;

                // Run an initial scan 15 seconds after app startup, then check periodically every 15 minutes
                _backgroundScanTimer = new Timer(async _ =>
                {
                    try
                    {
                        await CheckAndUploadLatestBackupSilentlyAsync();
                    }
                    catch { }
                }, null, TimeSpan.FromSeconds(15), TimeSpan.FromMinutes(15));
            }
            catch { }
        }

        private void OnNewBackupFileCreated(object sender, FileSystemEventArgs e)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    // Debounce to allow writing and file closing to finish
                    await Task.Delay(3500);
                    await CheckAndUploadLatestBackupSilentlyAsync();
                }
                catch { }
            });
        }

        public async Task CheckAndUploadLatestBackupSilentlyAsync()
        {
            if (!_cachedSettings.IsEnabled || !_cachedSettings.AutoUploadOnBackup)
            {
                return;
            }

            if (!await _uploadLock.WaitAsync(0))
            {
                return; // already an upload running
            }

            try
            {
                var defaultFolder = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
                    "POS_Cashier_Backups");

                if (!Directory.Exists(defaultFolder)) return;

                var dir = new DirectoryInfo(defaultFolder);
                var latestBackup = dir.GetFiles("POS_Backup_*.*")
                    .Where(f => f.Extension.Equals(".zip", StringComparison.OrdinalIgnoreCase) ||
                                f.Extension.Equals(".json", StringComparison.OrdinalIgnoreCase))
                    .OrderByDescending(f => f.LastWriteTimeUtc)
                    .FirstOrDefault();

                if (latestBackup == null) return;

                // Check if already uploaded
                if (string.Equals(latestBackup.Name, _cachedSettings.LastUploadedBackupFileName, StringComparison.OrdinalIgnoreCase))
                {
                    return; // Already up to date
                }

                // If it's a raw .json file, compress it to .zip first
                string fileToUpload = latestBackup.FullName;
                if (latestBackup.Extension.Equals(".json", StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        var jsonBytes = await File.ReadAllBytesAsync(latestBackup.FullName);
                        var (zipBytes, zipFileName) = CompressJsonBytes(jsonBytes, latestBackup.Name);
                        var zipPath = Path.Combine(defaultFolder, zipFileName);
                        await File.WriteAllBytesAsync(zipPath, zipBytes);
                        fileToUpload = zipPath;
                    }
                    catch { }
                }

                var (success, _, _) = await UploadBackupAsync(fileToUpload, _cachedSettings);
                if (success)
                {
                    _cachedSettings.LastUploadedBackupFileName = latestBackup.Name;
                    _cachedSettings.LastUploadedAtUtc = DateTime.UtcNow;
                    await SaveSettingsAsync(_cachedSettings);

                    // Prune local backups
                    PruneLocalBackups(defaultFolder, _cachedSettings.LocalRetentionCount > 0 ? _cachedSettings.LocalRetentionCount : 5);
                }
            }
            catch { }
            finally
            {
                _uploadLock.Release();
            }
        }

        public (byte[] ZipBytes, string ZipFileName) CompressJsonBytes(byte[] jsonBytes, string originalFileName)
        {
            var entryName = Path.GetFileName(originalFileName);
            if (!entryName.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
            {
                entryName += ".json";
            }

            var zipFileName = Path.ChangeExtension(entryName, ".zip");

            using var memoryStream = new MemoryStream();
            using (var archive = new ZipArchive(memoryStream, ZipArchiveMode.Create, leaveOpen: true))
            {
                var entry = archive.CreateEntry(entryName, CompressionLevel.Optimal);
                using var entryStream = entry.Open();
                entryStream.Write(jsonBytes, 0, jsonBytes.Length);
            }

            return (memoryStream.ToArray(), zipFileName);
        }

        public async Task<string> ExtractJsonFromBackupAsync(string filePath)
        {
            if (!File.Exists(filePath))
            {
                throw new FileNotFoundException("ملف النسخة الاحتياطية غير موجود.", filePath);
            }

            var ext = Path.GetExtension(filePath);
            if (ext.Equals(".zip", StringComparison.OrdinalIgnoreCase))
            {
                using var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
                using var archive = new ZipArchive(fileStream, ZipArchiveMode.Read);

                var jsonEntry = archive.Entries.FirstOrDefault(e => e.Name.EndsWith(".json", StringComparison.OrdinalIgnoreCase));
                if (jsonEntry == null)
                {
                    throw new InvalidDataException("الملف المضغوط لا يحتوي على ملف بيانات JSON صالحة.");
                }

                using var entryStream = jsonEntry.Open();
                using var reader = new StreamReader(entryStream, System.Text.Encoding.UTF8);
                return await reader.ReadToEndAsync();
            }
            else
            {
                return await File.ReadAllTextAsync(filePath, System.Text.Encoding.UTF8);
            }
        }

        public (int DeletedCount, long FreedBytes) PruneLocalBackups(string folderPath, int maxToKeep = 5)
        {
            if (string.IsNullOrWhiteSpace(folderPath) || !Directory.Exists(folderPath))
            {
                return (0, 0);
            }

            if (maxToKeep < 1) maxToKeep = 1;

            try
            {
                var dir = new DirectoryInfo(folderPath);
                var backupFiles = dir.GetFiles("POS_Backup_*.*")
                    .Where(f => f.Extension.Equals(".zip", StringComparison.OrdinalIgnoreCase) ||
                                f.Extension.Equals(".json", StringComparison.OrdinalIgnoreCase))
                    .OrderByDescending(f => f.LastWriteTimeUtc)
                    .ToList();

                if (backupFiles.Count <= maxToKeep)
                {
                    return (0, 0);
                }

                var filesToDelete = backupFiles.Skip(maxToKeep).ToList();
                int deletedCount = 0;
                long freedBytes = 0;

                foreach (var file in filesToDelete)
                {
                    try
                    {
                        var length = file.Length;
                        file.Delete();
                        deletedCount++;
                        freedBytes += length;
                    }
                    catch { }
                }

                return (deletedCount, freedBytes);
            }
            catch
            {
                return (0, 0);
            }
        }

        private AmazonS3Client CreateS3Client(CloudflareR2Settings settings)
        {
            if (string.IsNullOrWhiteSpace(settings.AccountId))
                throw new ArgumentException("معرف حساب Cloudflare (Account ID) مطلوب.");

            if (string.IsNullOrWhiteSpace(settings.AccessKeyId))
                throw new ArgumentException("مفتاح الوصول (Access Key ID) مطلوب.");

            if (string.IsNullOrWhiteSpace(settings.SecretAccessKey))
                throw new ArgumentException("المفتاح السري (Secret Access Key) مطلوب.");

            var config = new AmazonS3Config
            {
                ServiceURL = $"https://{settings.AccountId.Trim()}.r2.cloudflarestorage.com",
                AuthenticationRegion = "auto",
                ForcePathStyle = true,
                Timeout = TimeSpan.FromSeconds(60)
            };

            return new AmazonS3Client(settings.AccessKeyId.Trim(), settings.SecretAccessKey.Trim(), config);
        }

        public async Task<(bool Success, string? ErrorMessage)> TestConnectionAsync(CloudflareR2Settings settings)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(settings.BucketName))
                {
                    return (false, "يرجى إدخال اسم الـ Bucket (الحاوية).");
                }

                using var s3Client = CreateS3Client(settings);
                var request = new ListObjectsV2Request
                {
                    BucketName = settings.BucketName.Trim(),
                    MaxKeys = 1
                };

                var response = await s3Client.ListObjectsV2Async(request);
                return (true, null);
            }
            catch (AmazonS3Exception s3Ex)
            {
                return (false, $"خطأ من سيرفر Cloudflare R2: {s3Ex.ErrorCode} - {s3Ex.Message}");
            }
            catch (Exception ex)
            {
                return (false, $"فشل الاتصال: {ex.Message}");
            }
        }

        public async Task<(bool Success, string? ErrorMessage, string? RemoteKey)> UploadBackupAsync(string filePath, CloudflareR2Settings settings)
        {
            if (!File.Exists(filePath))
            {
                return (false, "ملف النسخة الاحتياطية غير موجود على الجهاز.", null);
            }

            try
            {
                using var s3Client = CreateS3Client(settings);
                var fileName = Path.GetFileName(filePath);
                var remoteKey = $"backups/{fileName}";

                var ext = Path.GetExtension(filePath).ToLowerInvariant();
                var contentType = ext == ".zip" ? "application/zip" : "application/json";

                using var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
                var putRequest = new PutObjectRequest
                {
                    BucketName = settings.BucketName.Trim(),
                    Key = remoteKey,
                    InputStream = fileStream,
                    ContentType = contentType
                };

                putRequest.Metadata.Add("uploaded-by", "ElectroPOS-Desktop");
                putRequest.Metadata.Add("original-name", fileName);
                putRequest.Metadata.Add("upload-date", DateTime.UtcNow.ToString("O"));

                var response = await s3Client.PutObjectAsync(putRequest);

                if (response.HttpStatusCode == System.Net.HttpStatusCode.OK ||
                    (int)response.HttpStatusCode >= 200 && (int)response.HttpStatusCode < 300)
                {
                    return (true, null, remoteKey);
                }

                return (false, $"استجاب السيرفر بكود غير متوقع: {response.HttpStatusCode}", null);
            }
            catch (AmazonS3Exception s3Ex)
            {
                return (false, $"خطأ أثناء رفع الملف إلى Cloudflare R2: {s3Ex.Message}", null);
            }
            catch (Exception ex)
            {
                return (false, $"فشل الرفع السحابي: {ex.Message}", null);
            }
        }

        public async Task<(bool Success, List<CloudBackupItem> Items, string? ErrorMessage)> ListCloudBackupsAsync(CloudflareR2Settings settings)
        {
            var list = new List<CloudBackupItem>();
            try
            {
                using var s3Client = CreateS3Client(settings);
                var request = new ListObjectsV2Request
                {
                    BucketName = settings.BucketName.Trim(),
                    Prefix = "backups/",
                    MaxKeys = 50
                };

                var response = await s3Client.ListObjectsV2Async(request);
                foreach (var obj in response.S3Objects)
                {
                    if (obj.Key.EndsWith("/")) continue;
                    list.Add(new CloudBackupItem
                    {
                        Key = obj.Key,
                        Size = obj.Size ?? 0,
                        LastModified = obj.LastModified ?? DateTime.MinValue
                    });
                }

                list = list.OrderByDescending(x => x.LastModified).ToList();
                return (true, list, null);
            }
            catch (Exception ex)
            {
                return (false, list, $"فشل جلب قائمة النسخ السحابية: {ex.Message}");
            }
        }

        public async Task<(bool Success, string? ErrorMessage)> DeleteCloudBackupAsync(string key, CloudflareR2Settings settings)
        {
            try
            {
                using var s3Client = CreateS3Client(settings);
                var request = new DeleteObjectRequest
                {
                    BucketName = settings.BucketName.Trim(),
                    Key = key
                };

                await s3Client.DeleteObjectAsync(request);
                return (true, null);
            }
            catch (Exception ex)
            {
                return (false, $"فشل حذف النسخة من السحابة: {ex.Message}");
            }
        }

        public void Dispose()
        {
            if (!_isDisposed)
            {
                _isDisposed = true;
                _folderWatcher?.Dispose();
                _backgroundScanTimer?.Dispose();
                _uploadLock?.Dispose();
            }
        }
    }
}
