package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("ReadingTimeDaily")
public class ReadingTimeDaily {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String userId;
    private LocalDate date; // 注意这里是 DATE 类型
    private Integer duration;
    private Integer targetDuration;
    private Boolean isAchieved; // TINYINT(1)
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}