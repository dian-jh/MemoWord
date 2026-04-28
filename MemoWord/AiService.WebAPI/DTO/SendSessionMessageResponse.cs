namespace AiService.WebAPI.DTO;

public sealed class SendSessionMessageResponse
{
    public string SessionId { get; init; } = string.Empty;

    public AiChatMessageDto UserMessage { get; init; } = null!;

    public AiChatMessageDto AssistantMessage { get; init; } = null!;
}
