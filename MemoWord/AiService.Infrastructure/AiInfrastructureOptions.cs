namespace AiService.Infrastructure;

public sealed class AiInfrastructureOptions
{
    public string Model { get; init; } = "deepseek-chat";

    public float Temperature { get; init; } = 0.7f;

    public bool EnableDistributedCache { get; init; } = true;
}
