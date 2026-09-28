namespace POS.Shared.Application.Exceptions;

public sealed record ValidationError(string PropertyName, string ErrorMessage);