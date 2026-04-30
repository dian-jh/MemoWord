package com.ebook.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.ebook.entity.ReadingTimeDaily;
import org.springframework.stereotype.Service;


public interface ReadingService extends IService<ReadingTimeDaily> {

    void addDuration(Integer seconds);
//    void autoCreateTodayRecord();
}
