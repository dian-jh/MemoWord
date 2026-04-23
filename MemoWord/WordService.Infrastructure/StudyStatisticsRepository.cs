using Microsoft.EntityFrameworkCore;
using WordService.Domain;
using WordService.Domain.Entities;

namespace WordService.Infrastructure;

public class StudyStatisticsRepository : IStudyStatisticsRepository
{
    private readonly WordDbContext _dbContext;

    public StudyStatisticsRepository(WordDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<StudyStatistics?> GetByUserIdAndDateAsync(Guid userId, DateTime statDate, CancellationToken cancellationToken = default)
    {
        var date = statDate.Date;
        return _dbContext.Set<StudyStatistics>()
            .FirstOrDefaultAsync(x => x.UserId == userId && x.StatDate == date, cancellationToken);
    }

    public Task<List<StudyStatistics>> GetByUserIdOrderByDateAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return _dbContext.Set<StudyStatistics>()
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.StatDate)
            .ToListAsync(cancellationToken);
    }

    public Task AddAsync(StudyStatistics studyStatistics, CancellationToken cancellationToken = default)
    {
        return _dbContext.Set<StudyStatistics>().AddAsync(studyStatistics, cancellationToken).AsTask();
    }

    public void Update(StudyStatistics studyStatistics)
    {
        _dbContext.Set<StudyStatistics>().Update(studyStatistics);
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return _dbContext.SaveChangesAsync(cancellationToken);
    }
}
