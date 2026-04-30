package com.ebook.dto;

import com.baomidou.mybatisplus.annotation.TableField;
import lombok.Data;

@Data
public class UpdatePasswordDTO {


    private String oldPassword;
    private String newPassword;
}
