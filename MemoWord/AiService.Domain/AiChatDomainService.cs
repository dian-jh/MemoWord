using AiService.Domain.Entities;
using AiService.Domain.Models;

namespace AiService.Domain;

public class AiChatDomainService
{
    private readonly IAiChatRepository _aiChatRepository;
    private readonly IAiCompletionProvider _aiCompletionProvider;

    public AiChatDomainService(
        IAiChatRepository aiChatRepository,
        IAiCompletionProvider aiCompletionProvider)
    {
        _aiChatRepository = aiChatRepository;
        _aiCompletionProvider = aiCompletionProvider;
    }

    public async Task<AiSendMessageResult> SendMessageAsync(
        Guid userId,
        string sessionId,
        string content,
        int historyLimit,
        string? systemPrompt,
        CancellationToken cancellationToken = default)
    {
        var normalizedSessionId = NormalizeSessionId(sessionId);
        var normalizedContent = NormalizeContent(content);

        var session = await _aiChatRepository.GetSessionAsync(userId, normalizedSessionId, cancellationToken);
        var isNewSession = session is null;
        if (isNewSession)
        {
            session = new AiChatSession(userId, normalizedSessionId);
            await _aiChatRepository.AddSessionAsync(session, cancellationToken);
        }

        if (session is null)
        {
            throw new InvalidOperationException("Failed to initialize AI chat session.");
        }

        var safeHistoryLimit = Math.Clamp(historyLimit, 1, 200);
        var history = await _aiChatRepository.GetMessagesBySessionIdAsync(session.Id, safeHistoryLimit, cancellationToken);

        var promptMessages = new List<AiChatPromptMessage>(history.Count + 2);
        if (!string.IsNullOrWhiteSpace(systemPrompt))
        {
            promptMessages.Add(new AiChatPromptMessage
            {
                Role = AiChatRoles.System,
                Content = systemPrompt.Trim()
            });
        }

        promptMessages.AddRange(history.Select(x => new AiChatPromptMessage
        {
            Role = x.Role,
            Content = x.Content
        }));

        promptMessages.Add(new AiChatPromptMessage
        {
            Role = AiChatRoles.User,
            Content = normalizedContent
        });

        var assistantContent = await _aiCompletionProvider.GetCompletionAsync(promptMessages, cancellationToken);

        var userMessage = AiChatMessage.CreateUserMessage(session.Id, userId, normalizedContent);
        var assistantMessage = AiChatMessage.CreateAssistantMessage(session.Id, userId, assistantContent);

        session.Touch();
        await _aiChatRepository.AddMessageAsync(userMessage, cancellationToken);
        await _aiChatRepository.AddMessageAsync(assistantMessage, cancellationToken);
        if (!isNewSession)
        {
            _aiChatRepository.UpdateSession(session);
        }
        await _aiChatRepository.SaveChangesAsync(cancellationToken);

        return new AiSendMessageResult
        {
            SessionId = session.SessionKey,
            UserMessage = userMessage,
            AssistantMessage = assistantMessage
        };
    }

    public async Task<List<AiChatMessage>> GetMessagesAsync(
        Guid userId,
        string sessionId,
        int take,
        CancellationToken cancellationToken = default)
    {
        if (take <= 0)
        {
            return [];
        }

        var normalizedSessionId = NormalizeSessionId(sessionId);
        var session = await _aiChatRepository.GetSessionAsync(userId, normalizedSessionId, cancellationToken);
        if (session is null)
        {
            return [];
        }

        return await _aiChatRepository.GetMessagesBySessionIdAsync(session.Id, take, cancellationToken);
    }

    private static string NormalizeSessionId(string sessionId)
    {
        if (string.IsNullOrWhiteSpace(sessionId))
        {
            throw new ArgumentException("sessionId cannot be empty.", nameof(sessionId));
        }

        return sessionId.Trim();
    }

    private static string NormalizeContent(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("content cannot be empty.", nameof(content));
        }

        return content.Trim();
    }
}
