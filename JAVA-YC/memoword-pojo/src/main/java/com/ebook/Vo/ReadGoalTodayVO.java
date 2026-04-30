package com.ebook.Vo;

import lombok.Data;

// GET /api/v1/read-goal/today (VO)
@Data
public class ReadGoalTodayVO {
    private String date; // yyyy-MM-dd
    private Integer durationSec;
    private Integer targetSec;
    private Integer remainingSec; // TargetDuration - Duration
    private Boolean isAchieved;
}