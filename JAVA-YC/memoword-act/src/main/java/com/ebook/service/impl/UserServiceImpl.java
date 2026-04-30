package com.ebook.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.ebook.Vo.LoginVO;
import com.ebook.Vo.UserVO;
import com.ebook.dto.LoginDTO;
import com.ebook.dto.RegisterDTO;
import com.ebook.exception.BusinessException;
import com.ebook.mapper.UserMapper;
import com.ebook.properties.JwtProperties;
import com.ebook.service.UserService;
import com.ebook.utils.JwtUtil;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import com.ebook.entity.User;
import com.ebook.exception.BusinessException;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper,User> implements UserService {

    @Autowired
    private JwtProperties jwtProperties;
    @Autowired
    private UserMapper userMapper;

    public User login(LoginDTO loginDTO) {


        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        // 匹配数据库 account 字段
        wrapper.eq(User::getAccount, loginDTO.getAccount());

        // 查询单个用户对象
        User user = getOne(wrapper);

        // 2. 账号校验
        if (user == null) {
            throw new BusinessException("账号或密码错误"); // 模糊提示增强安全性
        }

        // 3. 密码校验 (假设使用 BCrypt 对 PasswordHash 进行比对)
        // 记得在 pom 中引入 spring-boot-starter-security
        //TODO exception
        if (!BCrypt.checkpw(loginDTO.getPassword(), user.getPasswordHash())) {
            throw new BusinessException("账号或密码错误");
        }
        return user;
    }

    @Override
    public User registry(RegisterDTO registerDTO) {
        // 1. 账号唯一性校验
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getAccount, registerDTO.getAccount());
        if (count(wrapper) > 0) {
            throw new BusinessException("账号已存在");
        }

        // 2. 密码加密 (使用 BCrypt)
        String passwordHash = BCrypt.hashpw(registerDTO.getPassword(), BCrypt.gensalt());

        // 3. 创建用户对象并保存到数据库
        User user = new User();
        String userId = UUID.randomUUID().toString();
        user.setAccount(registerDTO.getAccount());
        user.setPasswordHash(passwordHash);
        user.setId(userId);
        user.setUsername(registerDTO.getUsername());
        LocalDateTime time =  LocalDateTime.now();
        user.setCreateTime(time);
        save(user); // 使用 MyBatis-Plus 的 save 方法

        return user;

    }


}
