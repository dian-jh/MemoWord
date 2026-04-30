package com.ebook.Vo;

import lombok.Data;

// GET /api/v1/library/books/{bookId} (图书完整详情 VO)
@Data
public class BookDetailVO {
    private String id;
    private String readerBookKey;
    private String fileUrl;
    private String title;
    private String author;
    private String coverUrl;
    private String format;
    private String fileName;
    private Long fileSize;
    private Integer totalCatalogCount;
    private Integer catalogVersion;
    private ProgressVO progress; // 嵌套当前进度
    private String createTime;
    private String updateTime;
}