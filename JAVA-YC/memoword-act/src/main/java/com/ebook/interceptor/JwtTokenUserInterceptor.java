package com.ebook.interceptor;


import com.ebook.constant.JwtClaimsConstant;
import com.ebook.context.BaseContext;
import com.ebook.properties.JwtProperties;
import com.ebook.utils.JwtUtil;
import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * jwt令牌校验的拦截器
 */
@Component
@Slf4j
public class JwtTokenUserInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtProperties jwtProperties;

    /**
     * 校验jwt
     *
     * @param request
     * @param response
     * @param handler
     * @return
     * @throws Exception
     */
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        //这里的preHandle指的是在请求到达Controller之前先执行这个方法，来校验jwt令牌是否合法，如果合法就放行，如果不合法就响应401状态码

        System.out.println("当前线程的id"+Thread.currentThread().getId());
        //判断当前拦截到的是Controller的方法还是其他资源
        if (!(handler instanceof HandlerMethod)) {
            //当前拦截到的不是动态方法，直接放行
            return true;
        }

        //1、从请求头中获取令牌
        String token = request.getHeader(jwtProperties.getUserTokenName());//这里为什么不用token，
        // 前端传来的不是token吗？解释：前端传来的确实是token，但是在后端我们需要使用一个变量来接收这个token值。
        // 这个变量的名字可以是任意的，但为了代码的清晰和可读性，我们通常会使用一个有意义的名字，比如token。
        // 这个变量名只是我们在代码中使用的一个标识符，它并不影响我们从请求头中获取到的实际值。
        // 所以，虽然前端传来的确实是token，但在后端我们可以使用任何合法的变量名来接收这个值，这样做是完全正常的。


        //2、校验令牌
        try {
            log.info("jwt校验:{}", token);
            Claims claims = JwtUtil.parseJWT(jwtProperties.getUserSecretKey(), token);
            //这里的claims是一个map集合，里面存储了我们在生成jwt时放入的那些数据，比如员工id
            String userId = claims.get(JwtClaimsConstant.USER_ID).toString();
            log.info("当前阅读者id：", userId);

            BaseContext.setCurrentId(userId);
            //3、通过，放行
            return true;
        } catch (Exception ex) {
            //4、不通过，响应401状态码
            response.setStatus(401);
            return false;
        }
    }
}
