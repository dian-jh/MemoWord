package com.ebook.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * Reader Kit 定位信息 (文档 3.2.4 & 5.5)
 * 用于描述书籍内部的具体位置
 */
@Data
public class PositionDTO {
    // 类型：CFI / DOM_POS / PAGE_INDEX
    private String locatorType;
    // 定位值字符串
    private String locatorValue;
    // 章节ID (关联 BookCatalogs.Id)
    private String catalogId;
    // 进度百分比 (0~1)
    private BigDecimal progressRatio;
}