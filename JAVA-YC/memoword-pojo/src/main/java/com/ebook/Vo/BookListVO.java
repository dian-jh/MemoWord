package com.ebook.Vo;

import lombok.Data;

import java.math.BigDecimal;

// GET /api/v1/library/books (书库列表项 VO)
@Data
public class BookListVO {
    private String id;
    private String title;
    private String author;
    private String coverUrl;
    private String format;
    private Integer totalCatalogCount;
    private BigDecimal progressRatio;
    private String lastReadAt;
}