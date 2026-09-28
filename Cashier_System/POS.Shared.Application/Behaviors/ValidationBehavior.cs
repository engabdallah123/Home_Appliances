using FluentValidation;
using MediatR;
using POS.Shared.Application.Exceptions;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace POS.Shared.Application.Behaviors;

public class ValidationBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IBaseCommand
{
    private readonly IEnumerable<IValidator<TRequest>> validators;


    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        this.validators = validators;
    }
    public async Task<TResponse> Handle(TRequest request,
                                        RequestHandlerDelegate<TResponse> next,
                                        CancellationToken cancellationToken)
    {
        // if there is no fluent validtion of this command don't do anything
        if (!validators.Any())
        {
            return await next();
        }


        // else => get all errors and display them in custom exception if there


        /*
         *ValidationContext<T> is just a wrapper around an object that you want to validate.
            It helps FluentValidation know which object it is working on.
            Think of it as a box 📦 that holds the object inside.
            Validators open the box, take out the object, and check if it meets the rules.
         */


        var context = new ValidationContext<TRequest>(request);


        var validationErrors = validators
            .Select(validator => validator.Validate(context))
            .Where(validationResult => validationResult.Errors.Any())
            .SelectMany(validationResult => validationResult.Errors)
            .Select(validationFailure => new ValidationError(
                validationFailure.PropertyName,
                validationFailure.ErrorMessage))
            .ToList();



        if (validationErrors.Any())
        {
            // استخدم Select بدلاً من SelectMany للحفاظ على الجملة كاملة
            var errorMessage = string.Join(" | ", validationErrors.Select(e => e.ErrorMessage));

            return (TResponse)(object)Result<Guid>.Failure(
                new Error("Validation", errorMessage));
        }

        return await next();


    }
}