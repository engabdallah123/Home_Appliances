using Microsoft.AspNetCore.Http;
using POS.Shared.Domain;
namespace POS.Shared.Application.IService
{
    public interface IFileService
    {
        #region before
        //public Task<string> UploadFileAsync(IFormFile file, string folder);
        //public Task DeleteFileAsync(string FilePath);
        //public Task<IFormFile> GetFileAsIFormFileAsync(string imageSrc);
        //Task DeleteAllFilesAsync(List<string> FilePaths);
        //Task<byte[]> GetFileAsByteArrayAsync(string imageSrc);
        //Task<string> UploadFileAsync(IFormFile file, string folder, HttpRequest request); 
        #endregion

        Task<Result> DeleteFileAsync(string filePath);

        Task<Result> DeleteAllFilesAsync(List<string> filePaths);

        Task<Result<string>> UploadFileAsync(IFormFile file, string folder);

        Task<Result<byte[]>> GetFileAsByteArrayAsync(string imageSrc);

        Task<Result<IFormFile>> GetFileAsIFormFileAsync(string imageSrc);

        Task<Result<string>> UploadFileWithUrlAsync(
            IFormFile file,
            string folder,
            string baseUrl);
    }
}
