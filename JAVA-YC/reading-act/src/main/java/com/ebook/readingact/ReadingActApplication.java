package com.ebook.readingact;

import lombok.extern.slf4j.Slf4j;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

//@EnableCaching              // 开启 Redis 缓存注解支持
//@EnableAspectJAutoProxy     // 开启 AOP 切面支持
@MapperScan("com.ebook.mapper") // 严格匹配你的 Mapper 接口包名
@ComponentScan(basePackages = {"com.ebook"}) // 确保扫描到 ebook-pojo 里的组件
@SpringBootApplication
@Slf4j

public class ReadingActApplication {

    public static void main(String[] args) {
        SpringApplication.run(ReadingActApplication.class, args);
        log.info("server started");

    }

}
