using WordService.Domain.Entities;

namespace WordService.Domain;

public interface IStudyStatisticsRepository
{
    Task<StudyStatistics?> GetByUserIdAndDateAsync(Guid userId, DateTime statDate, CancellationToken cancellationToken = default);

    Task<List<StudyStatistics>> GetByUserIdOrderByDateAsync(Guid userId, CancellationToken cancellationToken = default);

    Task AddAsync(StudyStatistics studyStatistics, CancellationToken cancellationToken = default);

    void Update(StudyStatistics studyStatistics);

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
