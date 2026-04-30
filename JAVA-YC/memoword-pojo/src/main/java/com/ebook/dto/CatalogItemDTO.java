package com.ebook.dto;

import lombok.Data;

@Data
public class CatalogItemDTO {
    private String catalogId;       // 对应 RK 内部 ID
    private String parentCatalogId;
    private String title;
    private Integer orderNum;
    private Integer depthLevel;
    private String href;            // RK 定位符
    private String locator;         // 恢复定位值
}