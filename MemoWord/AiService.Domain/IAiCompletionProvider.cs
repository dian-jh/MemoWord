using AiService.Domain.Models;

namespace AiService.Domain;

public interface IAiCompletionProvider
{
    Task<string> GetCompletionAsync(IReadOnlyList<AiChatPromptMessage> messages, CancellationToken cancellationToken = default);
}
