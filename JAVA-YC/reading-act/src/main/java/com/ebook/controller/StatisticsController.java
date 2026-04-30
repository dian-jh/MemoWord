package com.ebook.controller;


import com.ebook.Vo.ReadGoalTodayVO;
import com.ebook.context.BaseContext;
import com.ebook.entity.ReadingTimeDaily;
import com.ebook.result.Result;
import com.ebook.service.ReadingService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Slf4j
@Api(tags = "阅读统计相关接口")
@RequestMapping("/api/v1")
public class StatisticsController {


    @Autowired
    private ReadingService readingService;

//
//    路由：`GET /api/v1/read-goal/today`
//            - 入参：无
//
//    出参：
//
//            ```json
//    {
//        "date": "2026-04-18",
//            "durationSec": 64,
//            "targetSec": 300,
//            "remainingSec": 236,//remainingSec = TargetDuration - Duration
//            "isAchieved": false
//    }
//```
    @ApiOperation("获取今日阅读目标完成情况")
    @GetMapping("/read-goal/today")
    public Result<ReadGoalTodayVO> getTodayReadingProgress()
    {
        String userId = BaseContext.getCurrentId();
        ReadingTimeDaily readingTimeDaily=  readingService.getById(userId);
        ReadGoalTodayVO readGoalTodayVO = new ReadGoalTodayVO();
        BeanUtils.copyProperties(readingTimeDaily,readGoalTodayVO);
        return  Result.success(readGoalTodayVO);

    }

//    @ApiOperation()
}
