package com.ebook.Vo;

import lombok.Data;

// GET /api/v1/reading-progress/{bookId} (VO)
@Data
public class ProgressVO {
    private String bookId;
    private Boolean hasProgress;
    private PositionDTO position;
    private Integer version; // 当前服务端版本号
    private String updatedAt;
}