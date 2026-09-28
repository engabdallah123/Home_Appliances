using System.Net.Http;
using System.Net.Http.Headers;

namespace POS.Desktop.Services.Auth
{
    public class BearerTokenHandler : DelegatingHandler
    {
        private readonly CustomAuthStateProvider _authStateProvider;

        public BearerTokenHandler(CustomAuthStateProvider authStateProvider)
        {
            _authStateProvider = authStateProvider;
        }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var token = _authStateProvider.Token;
            if (!string.IsNullOrEmpty(token))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            }

            return await base.SendAsync(request, cancellationToken);
        }
    }
}
