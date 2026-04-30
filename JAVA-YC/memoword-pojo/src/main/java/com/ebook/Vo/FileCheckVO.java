package com.ebook.Vo;

import lombok.Data;

// 文件校验结果 (VO)
@Data
public class FileCheckVO {
    private Boolean exists;
    private String fileUrl; // 如果存在，直接返回可用的 URL
}