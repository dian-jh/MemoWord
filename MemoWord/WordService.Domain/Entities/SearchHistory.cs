namespace WordService.Domain.Entities;

public class SearchHistory
{
    public Guid Id { get; private set; }

    public Guid UserId { get; private set; }

    public int WordId { get; private set; }

    public DateTime CreateTime { get; private set; }

    // For EF Core
    private SearchHistory() { }

    public SearchHistory(Guid userId, int wordId)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        WordId = wordId;
        CreateTime = DateTime.Now;
    }
}
