package com.ebook.Vo;

import lombok.Data;

@Data
public class ProgressConflictVO {
    private String errorCode; // READ_PROGRESS_CONFLICT
    private String message;
    private Integer serverVersion; // 服务端最新版本
}