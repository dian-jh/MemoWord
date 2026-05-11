namespace AiService.Infrastructure;

public sealed class DeepSeekOptions
{
    public string Endpoint { get; init; } = "https://api.deepseek.com/v1";

    public string ApiKey { get; init; } = string.Empty;
}
