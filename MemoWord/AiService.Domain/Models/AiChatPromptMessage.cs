namespace AiService.Domain.Models;

public sealed class AiChatPromptMessage
{
    public string Role { get; init; } = string.Empty;

    public string Content { get; init; } = string.Empty;
}
