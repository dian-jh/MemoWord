using AiService.Domain;
using AiService.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AiService.Infrastructure;

public class AiChatRepository : IAiChatRepository
{
    private readonly AiDbContext _dbContext;

    public AiChatRepository(AiDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<AiChatSession?> GetSessionAsync(Guid userId, string sessionId, CancellationToken cancellationToken = default)
    {
        return _dbContext.AiChatSessions
            .FirstOrDefaultAsync(x => x.UserId == userId && x.SessionKey == sessionId, cancellationToken);
    }

    public async Task<List<AiChatMessage>> GetMessagesBySessionIdAsync(Guid sessionId, int take, CancellationToken cancellationToken = default)
    {
        if (take <= 0)
        {
            return [];
        }

        return await _dbContext.AiChatMessages
            .AsNoTracking()
            .Where(x => x.SessionId == sessionId)
            .OrderByDescending(x => x.CreateTime)
            .Take(take)
            .OrderBy(x => x.CreateTime)
            .ToListAsync(cancellationToken);
    }

    public Task AddSessionAsync(AiChatSession session, CancellationToken cancellationToken = default)
    {
        return _dbContext.AiChatSessions.AddAsync(session, cancellationToken).AsTask();
    }

    public Task AddMessageAsync(AiChatMessage message, CancellationToken cancellationToken = default)
    {
        return _dbContext.AiChatMessages.AddAsync(message, cancellationToken).AsTask();
    }

    public void UpdateSession(AiChatSession session)
    {
        _dbContext.AiChatSessions.Update(session);
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return _dbContext.SaveChangesAsync(cancellationToken);
    }
}
