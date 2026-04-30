package com.ebook.Vo;

import lombok.Data;

// GET /api/v1/read-goal/year-summary
@Data
public class YearSummaryVO {
    private Integer year;
    private Integer booksReadCount;
    private Integer booksTarget;
    private Integer booksRemaining;
}