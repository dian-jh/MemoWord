using System;
using System.Collections.Generic;
using System.Text;

namespace WordService.Domain.Entities;

public class StudyStatistics
{
    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public DateTime StatDate { get; private set; }
    public int LearnedCount { get; private set; }
    public int TargetCount { get; private set; }
    public int StudyDuration { get; private set; } // 分钟
    public DateTime CreateTime { get; private set; }
    public DateTime UpdateTime { get; private set; }

    // EF Core 需要的私有构造函数
    private StudyStatistics() { }

    // 业务构造函数
    public StudyStatistics(Guid userId, DateTime statDate, int targetCount)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        StatDate = statDate.Date; // 确保只保留日期部分
        TargetCount = targetCount;
        LearnedCount = 0;
        StudyDuration = 0;
    }

    // 业务方法示例：更新学习进度
    public void UpdateProgress(int learnedIncremental, int durationIncremental)
    {
        LearnedCount += learnedIncremental;
        StudyDuration += durationIncremental;
    }
}