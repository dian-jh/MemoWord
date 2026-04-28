using AiService.Domain.Entities;

namespace AiService.Domain.Models;

public sealed class AiSendMessageResult
{
    public string SessionId { get; init; } = string.Empty;

    public AiChatMessage UserMessage { get; init; } = null!;

    public AiChatMessage AssistantMessage { get; init; } = null!;
}
