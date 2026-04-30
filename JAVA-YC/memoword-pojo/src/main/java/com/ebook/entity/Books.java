package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("Books")
public class Books {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String userId;
    private String title;
    private String fileHash;
    private String fileUrl;
    private String author;
    private String coverUrl;
    private String intro;
    private String format;
    private String readerBookKey;
    private String fileName;
    private Long fileSize;
    private Integer totalCatalogCount;
    private LocalDateTime lastReadAt;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    @TableLogic
    private LocalDateTime deletedAt; // 软删除
}