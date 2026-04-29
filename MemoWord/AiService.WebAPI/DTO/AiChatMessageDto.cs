namespace AiService.WebAPI.DTO;

public sealed class AiChatMessageDto
{
    public Guid Id { get; init; }

    public string Role { get; init; } = string.Empty;

    public string Content { get; init; } = string.Empty;

    public DateTime CreateTime { get; init; }
}
