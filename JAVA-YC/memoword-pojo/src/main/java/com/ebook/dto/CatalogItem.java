package com.ebook.dto;

import lombok.Data;
import java.util.List;

@Data
public class CatalogItem {
    private String catalogId;       // 对应 Reader Kit 内部 ID
    private String parentCatalogId;
    private String title;
    private Integer orderNum;
    private Integer depthLevel;
    private String href;            // Reader Kit 定位符
    private String locator;         // 客户端恢复定位值
    private List<CatalogItem> children; // 用于 tree=true 时的递归结构
}