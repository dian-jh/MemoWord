namespace AiService.Domain.Entities;

public class AiChatSession
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public string SessionKey { get; private set; } = string.Empty;

    public DateTime CreateTime { get; private set; }

    public DateTime UpdateTime { get; private set; }

    private AiChatSession()
    {
    }

    public AiChatSession(Guid userId, string sessionKey)
    {
        if (string.IsNullOrWhiteSpace(sessionKey))
        {
            throw new ArgumentException("sessionKey cannot be empty.", nameof(sessionKey));
        }

        Id = Guid.NewGuid();
        UserId = userId;
        SessionKey = sessionKey.Trim();
        CreateTime = DateTime.UtcNow;
        UpdateTime = CreateTime;
    }

    public void Touch()
    {
        UpdateTime = DateTime.UtcNow;
    }
}
