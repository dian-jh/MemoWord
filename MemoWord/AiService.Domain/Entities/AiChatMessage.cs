namespace AiService.Domain.Entities;

public class AiChatMessage
{
    public Guid Id { get; private set; }

    public Guid SessionId { get; private set; }

    public Guid UserId { get; private set; }

    public string Role { get; private set; } = string.Empty;

    public string Content { get; private set; } = string.Empty;

    public DateTime CreateTime { get; private set; }

    private AiChatMessage()
    {
    }

    private AiChatMessage(Guid sessionId, Guid userId, string role, string content)
    {
        if (!AiChatRoles.IsValid(role))
        {
            throw new ArgumentOutOfRangeException(nameof(role), "role is invalid.");
        }

        if (string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("content cannot be empty.", nameof(content));
        }

        Id = Guid.NewGuid();
        SessionId = sessionId;
        UserId = userId;
        Role = role;
        Content = content.Trim();
        CreateTime = DateTime.UtcNow;
    }

    public static AiChatMessage CreateUserMessage(Guid sessionId, Guid userId, string content)
    {
        return new AiChatMessage(sessionId, userId, AiChatRoles.User, content);
    }

    public static AiChatMessage CreateAssistantMessage(Guid sessionId, Guid userId, string content)
    {
        return new AiChatMessage(sessionId, userId, AiChatRoles.Assistant, content);
    }
}
