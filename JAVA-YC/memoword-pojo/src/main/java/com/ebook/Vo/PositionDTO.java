package com.ebook.Vo;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class PositionDTO {
    private String locatorType;  // CFI/DOM_POS/PAGE_INDEX
    private String locatorValue; // 具体定位值
    private String catalogId;    // 关联章节
    private BigDecimal progressRatio; // 0~1 精度
}