package com.ebook.dto;

import lombok.Data;
import java.util.List;


// POST /api/v1/books/{bookId}/annotations/sync
@Data
public class AnnotationSyncDTO {
    private String clientSyncId; // 同步批次ID
    private List<AnnotationUpsertDTO> upserts;
    private List<AnnotationDeleteDTO> deletes;
}