using System;
using System.Collections.Generic;
using System.Text;

namespace WordService.Domain.Entities;

public class UserFavorite
{
    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public int WordId { get; private set; }
    public DateTime CreateTime { get; private set; }

    // 给 EF Core 使用的私有构造函数
    private UserFavorite() { }

    public UserFavorite(Guid userId, int wordId)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        WordId = wordId;
        CreateTime = DateTime.Now;
    }
}