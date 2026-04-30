package com.ebook.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ebook.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper extends BaseMapper<User> {

    // 不需要写任何方法
    // MyBatis-Plus 自动提供：增删改查、分页、条件构造器等所有方法
}