using MediatR;
using POS.Shared.Domain;

namespace POS.Shared.Application.Messaging;

public interface IQuery<TResponse> : IRequest<Result<TResponse>>
{
}