package com.ebook.exception;

/**
 * 自定义业务异常
 * 用于登录失败、账号已存在、参数错误等业务提示
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}