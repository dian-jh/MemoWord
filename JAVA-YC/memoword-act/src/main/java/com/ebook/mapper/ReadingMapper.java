package com.ebook.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.ebook.entity.ReadingTimeDaily;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ReadingMapper extends BaseMapper<ReadingTimeDaily> {
}
