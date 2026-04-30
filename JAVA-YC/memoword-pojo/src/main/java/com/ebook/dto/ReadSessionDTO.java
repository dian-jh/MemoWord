package com.ebook.dto;

import lombok.Data;

// POST /api/v1/read-sessions/finish (强幂等)
@Data
public class ReadSessionDTO {
    private String sessionId; // 客户端会话唯一标识
    private String bookId;
    private String startedAt; // ISO 8601
    private String endedAt;   // ISO 8601
    private Integer durationSec;
    private PositionDTO position; // 结束时的位置快照
}