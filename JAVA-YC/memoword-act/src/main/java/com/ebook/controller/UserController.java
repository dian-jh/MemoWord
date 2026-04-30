package com.ebook.controller;

import com.ebook.Vo.LoginVO;
import com.ebook.Vo.UserVO;
import com.ebook.constant.JwtClaimsConstant;
import com.ebook.context.BaseContext;
import com.ebook.dto.LoginDTO;
import com.ebook.dto.RegisterDTO;
import com.ebook.dto.UpdatePasswordDTO;
import com.ebook.dto.UserUpdateDTO;
import com.ebook.entity.User;
import com.ebook.properties.JwtProperties;
import com.ebook.result.Result;
import com.ebook.service.UserService;
import com.ebook.utils.JwtUtil;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.v3.oas.annotations.Operation;
import lombok.experimental.Tolerate;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static com.ebook.result.Result.success;

@Api(tags = "用户认证管理")
@RestController
@RequestMapping("/api/v1")
@Slf4j
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtProperties jwtProperties;



    @ApiOperation("用户注册")
    @PostMapping("/auth/registry")
    public Result<String> registry(@RequestBody RegisterDTO registerDTO)
    {
        User user = userService.registry(registerDTO);
        log.info("用户注册了:{}"+registerDTO);
        return success(user.getId());
    }


    @ApiOperation("用户登录")
    @PostMapping("/auth/login")
    public Result<LoginVO> login(@RequestBody LoginDTO loginDTO) {

        log.info("用户登录了:{}"+loginDTO);
        User user = userService.login(loginDTO);
        UserVO userVO = new UserVO();
                BeanUtils.copyProperties(user, userVO);

        Map<String , Object> claims = new HashMap<>();
        claims.put(JwtClaimsConstant.USER_ID, user.getId());
        String token = JwtUtil.createJWT(jwtProperties.getUserSecretKey(), jwtProperties.getUserTtl(),claims);
        LoginVO loginVO = LoginVO.builder()
                .accessToken(token)
                .refreshToken(token)
                .expiresInSec(7200)
                .user(userVO)
                .build();


        return success(loginVO);
    }


    @GetMapping("/auth/logout")
    @ApiOperation("用户退出")

    public Result<Map<String, Boolean>> logout() {
        log.info("用户退出了");
        Map<String, Boolean> res = new HashMap<>();
        res.put("loggedOut", true);
        return success(res);
    }


//    ### 4.5 获取当前用户
//
//- 路由：`GET /api/v1/users/me`
//
//    入参：无
//
//    出参：
//
//            ```json
//    {
//        "id": "uuid",
//            "username": "张三",
//            "account": "13800000000",
//            "avatarUrl": "https://...",
//            "createTime": "2026-04-18T08:00:00+08:00"

    @GetMapping("/users/me")
    @ApiOperation("获取当前用户")
    public Result<UserVO> getCurrentUser()
    {

        String userId = BaseContext.getCurrentId();
        if (userId == null) {
            return Result.error("用户未登录");
        }

        // 2. 查询用户
        User user = userService.getById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }

//        User user =  userService.getById( userId);
         UserVO userVO = new UserVO();
         BeanUtils.copyProperties(user, userVO);
        return  Result.success(userVO);

    }



    @PutMapping("/users/updateme")
    @ApiOperation("修改当前登录用户信息") // 新版swagger注解
    public Result<String> updateCurrentUser(@RequestBody UserUpdateDTO userUpdateDTO) {
        // 1. 获取当前登录用户ID（UUID）
        String userId = BaseContext.getCurrentId();

        // 2. 判空（必须加，防止未登录）
        if (userId == null) {
            return Result.error("用户未登录");
        }

        // 3. 复制属性
        User user = new User();
        BeanUtils.copyProperties(userUpdateDTO, user);

        // 4. 【关键】必须设置用户ID，才能更新当前用户
        user.setId(userId);

        // 5. 执行更新
        userService.updateById(user);

        return Result.success("更新成功");
    }

    @PutMapping("/users/updatetargetwords/{num}")
    @ApiOperation("修改当前登录用户的目标单词数") // 新版swagger注解q
    public Result<String> updateTargetWords(@PathVariable Integer num)
    {

        String userId = BaseContext.getCurrentId();
        if (userId == null) {
            return Result.error("用户未登录");
        }
        User user = new User();
        user.setId(userId);
        user.setTargetWords(num);
        userService.updateById(user);
        return Result.success("更新目标单词数成功,当前目标单词数为:"+num);
    }


    @PostMapping("/users/upload")
    public Result upload(MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String suffix = originalFilename.substring(originalFilename.lastIndexOf("."));
        String fileName = UUID.randomUUID().toString() + suffix;

        // 保存到本地
        File dest = new File("D:/Vocabulary/uploads" + fileName);
        file.transferTo(dest);

        // 【关键】返回相对于域名的路径，不要写死 http://localhost
        // 前端收到后，会自行拼接穿透地址
        String relativeUrl = "/uploads/" + fileName;
        return Result.success(relativeUrl);
    }

    @PutMapping("/users/updatepassword")
    @ApiOperation("修改当前登录用户的密码")
    public Result<String> updatePassword(@RequestBody UpdatePasswordDTO updatePasswordDTO) {
        String userId = BaseContext.getCurrentId();
        log.info("用户{}准备修改密码，旧密码:{},新密码:{}",
                userId, updatePasswordDTO.getOldPassword(), updatePasswordDTO.getNewPassword());

        // 1. 判断是否登录
        if (userId == null) {
            return Result.error(401, "用户未登录");
        }

        // 2. 查询当前用户真实信息（包含正确的密码哈希）
        User currentUser = userService.getById(userId);
        if (currentUser == null) {
            return Result.error(404, "用户不存在");
        }

        // 3. 验证旧密码是否正确（BCrypt 正确用法）
        if (!BCrypt.checkpw(updatePasswordDTO.getOldPassword(), currentUser.getPasswordHash())) {
            return Result.error(400, "旧密码不正确");
        }

        // 4. 判断新密码不能与旧密码相同
        if (BCrypt.checkpw(updatePasswordDTO.getNewPassword(), currentUser.getPasswordHash())) {
            return Result.error(400, "新密码不能与旧密码相同");
        }

        // 5. 对新密码进行 BCrypt 加密（必须加密！）
        String newPasswordHash = BCrypt.hashpw(updatePasswordDTO.getNewPassword(), BCrypt.gensalt());

        // 6. 构造更新对象，只更新密码
        User updateUser = new User();
        updateUser.setId(userId);
        updateUser.setPasswordHash(newPasswordHash);

        // 7. 执行更新
        userService.updateById(updateUser);
        log.info("用户{}密码修改成功", userId);

        return Result.success();
    }




}