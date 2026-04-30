package com.ebook.dto;

import lombok.Data;

// POST /api/v1/library/books (注册本地图书)
@Data
public class BookRegisterDTO {
    private String readerBookKey; // 客户端唯一键
    private String fileHash;      // 用于秒传
    private String fileUrl;
    private String title;
    private String author;
    private String coverUrl;
    private String format;        // EPUB/TXT 等
    private String fileName;
    private Long fileSize;
    private Integer totalCatalogCount;
}