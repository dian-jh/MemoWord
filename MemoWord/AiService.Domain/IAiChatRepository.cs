using AiService.Domain.Entities;

namespace AiService.Domain;

public interface IAiChatRepository
{
    Task<AiChatSession?> GetSessionAsync(Guid userId, string sessionId, CancellationToken cancellationToken = default);

    Task<List<AiChatMessage>> GetMessagesBySessionIdAsync(Guid sessionId, int take, CancellationToken cancellationToken = default);

    Task AddSessionAsync(AiChatSession session, CancellationToken cancellationToken = default);

    Task AddMessageAsync(AiChatMessage message, CancellationToken cancellationToken = default);

    void UpdateSession(AiChatSession session);

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
