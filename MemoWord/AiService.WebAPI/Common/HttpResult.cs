namespace AiService.WebAPI.Common;

public sealed class HttpResult<T>
{
    public int Code { get; init; }

    public string Message { get; init; } = string.Empty;

    public T Data { get; init; } = default!;

    public static HttpResult<T> Success(T data, string message = "success")
    {
        return new HttpResult<T>
        {
            Code = StatusCodes.Status200OK,
            Message = message,
            Data = data
        };
    }

    public static HttpResult<T> Fail(string message, int code)
    {
        return new HttpResult<T>
        {
            Code = code,
            Message = message,
            Data = default!
        };
    }
}
