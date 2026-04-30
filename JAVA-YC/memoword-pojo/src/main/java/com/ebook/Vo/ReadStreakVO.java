package com.ebook.Vo;

import lombok.Data;

// GET /api/v1/read-goal/streak (VO)
@Data
public class ReadStreakVO {
    private Integer currentStreakCount;
    private Integer longestStreakCount;
    private String lastAchieveDate;
}