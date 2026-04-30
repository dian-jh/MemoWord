package com.ebook.dto;

import lombok.Data;

import java.util.Map;

@Data
public class AnnotationUpsertDTO {
    private String id; // UUID
    private String catalogId;
    private String quoteText;
    private String noteContent;
    private String style;
    private String type; // HIGHLIGHT/NOTE/BOOKMARK
    private Map<String, String> locator; // JSON 存储 start/end 的 CFI
    private String updatedAt;
}