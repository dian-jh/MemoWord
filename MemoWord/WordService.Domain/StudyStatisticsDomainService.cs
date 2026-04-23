using WordService.Domain.Entities;

namespace WordService.Domain;

public class StudyStatisticsDomainService
{
    private readonly IStudyStatisticsRepository _studyStatisticsRepository;

    public StudyStatisticsDomainService(IStudyStatisticsRepository studyStatisticsRepository)
    {
        _studyStatisticsRepository = studyStatisticsRepository;
    }

    public async Task<int> GetTodayTargetAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var today = DateTime.Today;
        var stat = await _studyStatisticsRepository.GetByUserIdAndDateAsync(userId, today, cancellationToken);
        return stat?.TargetCount ?? 0;
    }

    public async Task SetTodayTargetAsync(Guid userId, int targetCount, CancellationToken cancellationToken = default)
    {
        if (targetCount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(targetCount), "targetCount must be greater than 0.");
        }

        var today = DateTime.Today;
        var existing = await _studyStatisticsRepository.GetByUserIdAndDateAsync(userId, today, cancellationToken);

        if (existing is null)
        {
            var newStat = new StudyStatistics(userId, today, targetCount);
            await _studyStatisticsRepository.AddAsync(newStat, cancellationToken);
        }
        else
        {
            existing.SetTargetCount(targetCount);
            _studyStatisticsRepository.Update(existing);
        }

        await _studyStatisticsRepository.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> GetTodayLearnedCountAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var today = DateTime.Today;
        var stat = await _studyStatisticsRepository.GetByUserIdAndDateAsync(userId, today, cancellationToken);
        return stat?.LearnedCount ?? 0;
    }

    public async Task SetTodayLearnedCountAsync(Guid userId, int learnedCount, CancellationToken cancellationToken = default)
    {
        if (learnedCount < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(learnedCount), "learnedCount cannot be less than 0.");
        }

        var today = DateTime.Today;
        var existing = await _studyStatisticsRepository.GetByUserIdAndDateAsync(userId, today, cancellationToken);
        if (existing is null)
        {
            var newStat = new StudyStatistics(userId, today, 0);
            newStat.SetLearnedCount(learnedCount);
            await _studyStatisticsRepository.AddAsync(newStat, cancellationToken);
        }
        else
        {
            existing.SetLearnedCount(learnedCount);
            _studyStatisticsRepository.Update(existing);
        }

        await _studyStatisticsRepository.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> GetTodayStudyDurationAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var today = DateTime.Today;
        var stat = await _studyStatisticsRepository.GetByUserIdAndDateAsync(userId, today, cancellationToken);
        return stat?.StudyDuration ?? 0;
    }

    public async Task SetTodayStudyDurationAsync(Guid userId, int duration, CancellationToken cancellationToken = default)
    {
        if (duration < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(duration), "duration cannot be less than 0.");
        }

        var today = DateTime.Today;
        var existing = await _studyStatisticsRepository.GetByUserIdAndDateAsync(userId, today, cancellationToken);
        if (existing is null)
        {
            var newStat = new StudyStatistics(userId, today, 0);
            newStat.SetStudyDuration(duration);
            await _studyStatisticsRepository.AddAsync(newStat, cancellationToken);
        }
        else
        {
            existing.SetStudyDuration(duration);
            _studyStatisticsRepository.Update(existing);
        }

        await _studyStatisticsRepository.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<StudyStatistics>> GetLearnedHistoryAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _studyStatisticsRepository.GetByUserIdOrderByDateAsync(userId, cancellationToken);
    }
}
