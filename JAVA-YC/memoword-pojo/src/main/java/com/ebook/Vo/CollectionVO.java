package com.ebook.Vo;

import lombok.Data;

// GET /api/v1/collections (VO)
@Data
public class CollectionVO {
    private String id;
    private String name;
    private Integer sortOrder;
    private Integer bookCount;
    private Boolean isBuiltIn; // 是否为默认分类（如“图书”）
}