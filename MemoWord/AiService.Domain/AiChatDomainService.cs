using AiService.Domain.Entities;
using AiService.Domain.Models;

namespace AiService.Domain;

public class AiChatDomainService
{
    private readonly IAiChatRepository _aiChatRepository;
    private readonly IAiCompletionProvider _aiCompletionProvider;
    private readonly IAiWordLookupRepository _aiWordLookupRepository;

    public AiChatDomainService(
        IAiChatRepository aiChatRepository,
        IAiCompletionProvider aiCompletionProvider,
        IAiWordLookupRepository aiWordLookupRepository)
    {
        _aiChatRepository = aiChatRepository;
        _aiCompletionProvider = aiCompletionProvider;
        _aiWordLookupRepository = aiWordLookupRepository;
    }

    public async Task<AiSendMessageResult> SendMessageAsync(
        Guid userId,
        string sessionId,
        string content,
        int historyLimit,
        CancellationToken cancellationToken = default)
    {
        var normalizedSessionId = NormalizeSessionId(sessionId);
        var normalizedContent = NormalizeContent(content);
        var systemPrompt = AiSystemPromptProvider.GetBySessionKey(normalizedSessionId);

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
        var structuredOutput = AiStructuredOutputParser.Parse(assistantContent);
        var coreWords = await ResolveCoreWordsAsync(structuredOutput.CoreWords, cancellationToken);

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
            AssistantMessage = assistantMessage,
            Translation = structuredOutput.Translation,
            Analysis = structuredOutput.Analysis,
            CoreWords = coreWords
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

        var normalized = sessionId.Trim().ToUpperInvariant();
        if (!AiExpertTypes.IsSupported(normalized))
        {
            throw new ArgumentOutOfRangeException(nameof(sessionId), $"Unsupported session_key: {normalized}");
        }

        return normalized;
    }

    private static string NormalizeContent(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("content cannot be empty.", nameof(content));
        }

        return content.Trim();
    }

    private async Task<List<AiWordLookupItem>> ResolveCoreWordsAsync(
        IReadOnlyCollection<string> words,
        CancellationToken cancellationToken)
    {
        if (words.Count == 0)
        {
            return [];
        }

        var cleanedWords = words
            .Select(NormalizeCoreWordToken)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (cleanedWords.Count == 0)
        {
            return [];
        }

        var matchedWords = await _aiWordLookupRepository.GetByWordsAsync(cleanedWords, cancellationToken);
        var result = new List<AiWordLookupItem>(cleanedWords.Count);
        foreach (var word in cleanedWords)
        {
            if (matchedWords.TryGetValue(word, out var item))
            {
                result.Add(item);
            }
        }

        return result;
    }

    private static string NormalizeCoreWordToken(string word)
    {
        var token = word.Trim();
        if (token.Length == 0)
        {
            return token;
        }

        var start = 0;
        var end = token.Length - 1;
        while (start <= end && !char.IsLetterOrDigit(token[start]))
        {
            start++;
        }

        while (end >= start && !char.IsLetterOrDigit(token[end]))
        {
            end--;
        }

        if (start > end)
        {
            return string.Empty;
        }

        return token[start..(end + 1)];
    }
}
