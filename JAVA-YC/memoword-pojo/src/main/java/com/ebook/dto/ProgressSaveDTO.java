package com.ebook.dto;

import lombok.Data;

// PUT /api/v1/reading-progress/{bookId}
@Data
public class ProgressSaveDTO {
    private PositionDTO position;
    private Integer version; // 客户端持有的版本号
}