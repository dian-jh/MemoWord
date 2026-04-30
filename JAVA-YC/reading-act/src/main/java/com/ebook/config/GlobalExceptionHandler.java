package com.ebook.config;

import com.ebook.exception.BusinessException;
import com.ebook.result.Result;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // 捕获你代码里抛出的 BusinessException
    @ExceptionHandler(BusinessException.class)
    public Result handleBusinessException(BusinessException e) {
        // 打印日志方便后端调试
        System.err.println("业务异常拦截: " + e.getMessage());

        // 返回 100001，这样前端就能识别出是“账号已存在”
        // 注意：这里返回的是 200 OK 的响应体，内容是错误 JSON
        return Result.error(100001, e.getMessage());
    }

    // 捕获其他未知异常（防止前端直接看到堆栈信息）
    @ExceptionHandler(Exception.class)
    public Result handleException(Exception e) {
        e.printStackTrace();
        return Result.error(500, "服务器开小差了，请稍后再试");
    }
}