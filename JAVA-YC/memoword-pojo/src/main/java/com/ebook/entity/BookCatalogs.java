package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("BookCatalogs")
public class BookCatalogs {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String bookId;
    private String parentId;
    private String title;
    private Integer orderNum;
    private Integer depthLevel;
    private String href;
    private String locator;
    private LocalDateTime createTime;
}