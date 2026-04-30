package com.ebook.Vo;

import lombok.Data;

import java.util.List;

@Data
public class AnnotationSyncResultVO {
    private List<String> acceptedIds;
    private List<AnnotationConflict> conflicts;

    @Data
    public static class AnnotationConflict {
        private String id;
        private String reason; // server_newer
        private String serverUpdatedAt;
    }
}