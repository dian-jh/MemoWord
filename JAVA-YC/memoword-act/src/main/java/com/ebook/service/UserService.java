package com.ebook.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.ebook.dto.LoginDTO;
import com.ebook.dto.RegisterDTO;
import com.ebook.entity.User;

public interface UserService extends IService<User> {
    User login(LoginDTO loginDTO);

    User registry(RegisterDTO registerDTO);
}
