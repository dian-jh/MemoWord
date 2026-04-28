using AiService.Domain.Entities;
using AiService.Infrastructure.Entities;
using Microsoft.EntityFrameworkCore;

namespace AiService.Infrastructure;

public class AiDbContext : DbContext
{
    public AiDbContext(DbContextOptions<AiDbContext> options) : base(options)
    {
    }

    public DbSet<AiChatSession> AiChatSessions => Set<AiChatSession>();

    public DbSet<AiChatMessage> AiChatMessages => Set<AiChatMessage>();

    public DbSet<WordLookupEntity> Words => Set<WordLookupEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AiDbContext).Assembly);
    }
}
