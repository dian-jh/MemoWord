using Microsoft.EntityFrameworkCore;
using WordService.Domain.Entities;

namespace WordService.Infrastructure;

public class WordDbContext : DbContext
{
    public DbSet<Word> Words => Set<Word>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(WordDbContext).Assembly);
    }

}
