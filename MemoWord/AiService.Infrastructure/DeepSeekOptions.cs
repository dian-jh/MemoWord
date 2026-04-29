namespace AiService.Infrastructure;

public sealed class DeepSeekOptions
{
    public string Endpoint { get; init; } = "https://api.deepseek.com/v1";

    public string ApiKey { get; init; } = string.Empty;

    public string Model { get; init; } = "deepseek-chat";

    public double Temperature { get; init; } = 0.7;
}
