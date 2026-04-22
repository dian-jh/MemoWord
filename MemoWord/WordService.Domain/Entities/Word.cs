using System;
using System.Collections.Generic;
using System.Text;

namespace WordService.Domain.Entities;

public class Word
{
    // 使用私有设置器，符合 DDD 封装原则
    public int Id { get; private set; }
    public string WordContent { get; private set; } = string.Empty;
    public string? PhoneticEn { get; private set; }
    public string? PhoneticUs { get; private set; }
    public string? Definition { get; private set; }
    public string? Translation { get; private set; }
    public string? WordTags { get; private set; }
    public string? WordExchanges { get; private set; }
    public int BncLevel { get; private set; }
    public int FrqLevel { get; private set; }
    public int CollinsLevel { get; private set; }
    public int OxfordLevel { get; private set; }
    public string? ExampleSentences { get; private set; }

    private Word() { }

    public Word(int id, string content)
    {
        Id = id;
        WordContent = content;
    }
}