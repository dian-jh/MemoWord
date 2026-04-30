package com.ebook.context;

public class BaseContext {//基于ThreadLocal封装工具类，用户保存和获取当前登录用户id

    public static ThreadLocal<String> threadLocal = new ThreadLocal<>();

    public static void setCurrentId(String  id) {
        threadLocal.set(id);
    }

    public static String getCurrentId() {
        return threadLocal.get();
    }

    public static void removeCurrentId() {
        threadLocal.remove();
    }

}
