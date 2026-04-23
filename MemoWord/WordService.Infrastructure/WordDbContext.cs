using Microsoft.EntityFrameworkCore;
using WordService.Domain.Entities;

namespace WordService.Infrastructure;

public class WordDbContext : DbContext
{
    public WordDbContext(DbContextOptions<WordDbContext> options) : base(options)
    {
    }

    public DbSet<Word> Words => Set<Word>();

    public DbSet<StudyStatistics> StudyStatistics => Set<StudyStatistics>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(WordDbContext).Assembly);
    }

}
