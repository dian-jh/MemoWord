namespace AiService.WebAPI.Settings;

public sealed class AiChatApiOptions
{
    public string Model { get; init; } = "deepseek-chat";

    public double Temperature { get; init; } = 0.7;

    public int HistoryWindow { get; init; } = 20;
}
