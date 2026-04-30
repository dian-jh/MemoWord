package com.ebook.service.impl; // 注意包路径

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.ebook.mapper.ReadingMapper;
import com.ebook.entity.ReadingTimeDaily;
import com.ebook.service.ReadingService;
import org.springframework.stereotype.Service;

@Service
public class ReadingServiceImpl extends ServiceImpl<ReadingMapper, ReadingTimeDaily> implements ReadingService {
    @Override
    public void addDuration(Integer seconds) {

    }

    // 你的业务代码写在这里
}