//
//
// import { AxiosResponse } from '@ohos/axios'
// import { instance } from './Axios'
//
// // ======================== 类型定义 ========================
//
//
// // ================== 【新增】用户信息相关 ==================
// // ================== 用户信息修改 ==================
// export interface UpdateUserReq {
//   username: string;
//   avatarUrl?: string;
// }
//
// export interface UpdateUserRes {
//   updated: boolean;
// }
//
// // ✅ 显式指定所有泛型，避免 any
// export function updateMe(
//   data: UpdateUserReq
// ): Promise<AxiosResponse<UpdateUserRes>> {
//   return instance.put<UpdateUserRes, AxiosResponse<UpdateUserRes>>(
//     '/api/v1/users/me',
//     data
//   );
// }
//
//
// // 4.5 获取当前用户（你已有 info / getMe，我不动）
// // 4.6 更新当前用户（新增
// // 基础响应结构（仅用于旧的那些带 code 的接口）
// export interface LoginReq {
//   account: string;
//   password: string;
// }
//
// // 对应后端 UserVO
// export interface UserVO {
//   id: string;
//   username: string;
//   account: string;
//   avatarUrl: string;
//   createTime: string;
// }
//
// // 对应后端 LoginVO
// export interface LoginVO {
//   accessToken: string;
//   refreshToken: string;
//   expiresInSec: number;
//   user: UserVO;
// }
//
// // 对应后端统一返回结构
// export interface ApiResult<T> {
//   code: number;
//   msg: string;
//   data: T;
// }
//
// // 兼容你原来的名字，不用改页面代码
//
//
//
//
//
//
// export interface HttpResult<T> {
//   code: number
//   msg: string|null
//   data: T
// }
// export interface BusinessError {
//   code?: string | number;
//   msg?: string;
// }
// // 必须在 Api.ts 中导出此接口，MockData 才能引用
// export interface StudyWord {
//   id: number
//   wordContent: string
//   phoneticEn: string
//   phoneticUs: string
//   definition: string
//   translation: string
//   exampleSentences: string
// }
//
// export interface RegisterReq {
//   account: string;
//   username: string;
//   password: string;
// }
// export interface RegisterRes {
//   userId: string;
// }
//
//
//
// export interface AuthUserInfo {
//   id: string;
//   username: string;
//   account: string;
//   avatarUrl: string;
//   createTime?: string;
// }
//
// export interface LoginRes {
//   accessToken: string;
//   refreshToken: string;
//   expiresInSec: number;
//   user: AuthUserInfo;
// }
//
// export interface PostCard {
//   rightCount: number
//   answeredCount: number
//   timeUsed: number
// }
//
// export interface PostPageData {
//   records: PostRecord[]
//   total: number
// }
//
// // 定义一个专门的接口，不能直接写在 Promise 后面
// export interface LogoutRes {
//   loggedOut: boolean;
// }
//
// export  interface RouterError {
//   code: number;
//   msg: string;
// }
// export interface PostRecord {
//   id: number
//   postText: string
//   rightCount: number
//   answeredCount: number
//   timeUsed: number
//   createTime: string
//   likeCount: number
//   nickname: string
//   avatarUrl: string
//   isLike: boolean
// }
//
// // ======================== API 方法 ========================
//
// // 1. 注册 (无 HttpResult 包装)
// export function register(data: RegisterReq): Promise<AxiosResponse<RegisterRes>> {
//   return instance.post<RegisterRes>('/api/v1/auth/register', data)
// }
//
// // 2. 登录 (无 HttpResult 包装)
// // export function login(data: LoginReq): Promise<AxiosResponse<LoginRes>> {
// //   return instance.post<LoginRes>('/api/v1/auth/login', data)
// // }
//
// // 必须使用 HttpResult<LoginRes>，因为 RawData 显示有 code/data 包装
// export function login(data: LoginReq): Promise<AxiosResponse<HttpResult<LoginRes>>> {
//   return instance.post<HttpResult<LoginRes>>('/api/v1/auth/login', data);
// }
//
// //
// // export function info(): Promise<AxiosResponse<AuthUserInfo>> {
// //   return instance.get<AuthUserInfo, AxiosResponse<AuthUserInfo>>(
// //     '/api/v1/users/me'
// //   );
// // }
// // 简化后的 info 定义
// export function info(): Promise<AxiosResponse<AuthUserInfo>> {
//   // 只需要定义返回的具体 Data 类型即可
//   return instance.get<AuthUserInfo>('/api/v1/users/me');
// }
//
// export function getMe(): Promise<AxiosResponse<AuthUserInfo>> {
//   return instance.get<AuthUserInfo>('/api/v1/users/me')
// }
//
// // --- 帖子与打卡 (这部分如果后端还是旧的带 code 结构，则保留 HttpResult) ---
// export function getAllPost(page: number, size: number): Promise<AxiosResponse<HttpResult<PostPageData>>> {
//   return instance.get<HttpResult<PostPageData>>('/word/post/getAll', { params: { page, size } })
// }
//
// export function getMyPost(page: number, size: number): Promise<AxiosResponse<HttpResult<PostPageData>>> {
//   return instance.get<HttpResult<PostPageData>>('/word/post/getMine', { params: { page, size } })
// }
//
// export function like(postId: number): Promise<AxiosResponse<HttpResult<boolean>>> {
//   return instance.get<HttpResult<boolean>>('/word/like/create', { params: { postId } })
// }
//
// export function cancelLike(postId: number): Promise<AxiosResponse<HttpResult<boolean>>> {
//   return instance.get<HttpResult<boolean>>('/word/like/cancel', { params: { postId } })
// }
//
// export function createPost(post: PostCard): Promise<AxiosResponse<HttpResult<boolean>>> {
//   return instance.post<HttpResult<boolean>>('/word/post/create', post)
// }
//
// export function sendCode(phone: string): Promise<AxiosResponse<HttpResult<string>>> {
//   return instance.get<HttpResult<string>>('/word/user/code', { params: { phone } })
// }
//
// // ✅ 正确写法：使用 LogoutRes 接口名代替对象字面量
// export function logout(): Promise<AxiosResponse<LogoutRes>> {
//   return instance.post<LogoutRes>('/api/v1/auth/logout')
// }











import { AxiosResponse, FormData, InternalAxiosRequestConfig } from '@ohos/axios'
import { instance } from './Axios'

import request from '@ohos.request';
import fs from '@ohos.file.fs';



// 完全对齐 C# 后端返回的单词实体
export interface StudyWord {
  id: number;
  wordContent: string;
  phoneticEn: string;
  phoneticUs: string;
  definition: string;
  translation: string;
  exampleSentences: string;
}


// ======================== 1. 强制定义的业务模型 ========================

export interface AuthUserInfo {
  id: string
  username: string
  account: string
  avatarUrl: string
  createTime?: string
  targetWords: number
}
// 修改用户每日目标单词数
export function updateTargetWords(num: number): Promise<AxiosResponse<string>> {
  return instance.put<string, AxiosResponse<string>>(`/api/v1/users/updatetargetwords/${num}`);
}
// Api.ts 底部确认



// 对应后端的 BooleanResult (code, msg, data: boolean)
export function createPost(post: PostCard): Promise<AxiosResponse<BooleanResult>> {
  return instance.post<BooleanResult, AxiosResponse<BooleanResult>>('/word/post/create', post)
}

export interface LoginRes {
  accessToken: string
  refreshToken: string
  expiresInSec: number
  user: AuthUserInfo
}

export interface RegisterRes {
  userId: string
}

export interface UpdateUserRes {
  updated: boolean
}

export interface LogoutRes {
  loggedOut: boolean
}

export interface PostPageData {
  records: PostRecord[]
  total: number
}

export interface PostRecord {
  id: number
  postText: string
  rightCount: number
  answeredCount: number
  timeUsed: number
  createTime: string
  likeCount: number
  nickname: string
  avatarUrl: string
  isLike: boolean
}

// ======================== 2. 强制定义的后端包装类 (消除 <T>) ========================

export interface UserInfoResult {
  code: number
  msg: string | null
  data: AuthUserInfo
}

export interface LoginResult {
  code: number
  msg: string | null
  data: LoginRes
}

export interface RegisterResult {
  code: number
  msg: string | null
  data: RegisterRes
}

export interface UpdateUserResult {
  code: number
  msg: string | null
  data: UpdateUserRes
}

export interface PostPageResult {
  code: number
  msg: string | null
  data: PostPageData
}

export interface BooleanResult {
  code: number
  msg: string | null
  data: boolean
}

export interface StringResult {
  code: number
  msg: string | null
  data: string
}

// ======================== 3. 请求参数模型 ========================

export interface LoginReq {
  account: string
  password: string
}

export interface RegisterReq {
  account: string
  username: string
  password: string
}

export interface UpdateUserReq {
  username: string
  avatarUrl?: string
}

export interface PostCard {
  rightCount: number
  answeredCount: number
  timeUsed: number
}

// ======================== 4. 接口实现 (无解包逻辑，手动构建) ========================

// 登录：直接返回包装类
export function login(data: LoginReq): Promise<AxiosResponse<LoginResult>> {
  return instance.post<LoginResult, AxiosResponse<LoginResult>>('/api/v1/auth/login', data)
}

// 注册：直接返回包装类
export function register(data: RegisterReq): Promise<AxiosResponse<RegisterResult>> {
  return instance.post<RegisterResult, AxiosResponse<RegisterResult>>('/api/v1/auth/registry', data)
}

/**
 * 获取当前用户
 * ✅ 解决 ...res 爆红：手动提取属性构建新对象
 * ✅ 解决泛型爆红：使用 UserInfoResult
 */
export async function info(): Promise<AxiosResponse<AuthUserInfo>> {
  const res: AxiosResponse<UserInfoResult> = await instance.get<UserInfoResult, AxiosResponse<UserInfoResult>>('/api/v1/users/me')

  if (res.data.code !== 1) {
    throw new Error(res.data.msg || '获取用户信息失败')
  }

  // ArkTS 不允许 ...res，必须手动赋值
  const finalResponse: AxiosResponse<AuthUserInfo> = {
    data: res.data.data, // 将包装里的 data 提取出来
    status: res.status,
    statusText: res.statusText,
    headers: res.headers,
    config: res.config
  }
  return finalResponse
}

// 更新用户信息
export async function updateMe(data: UpdateUserReq): Promise<AxiosResponse<UpdateUserRes>> {
  const res: AxiosResponse<UpdateUserResult> = await instance.put<UpdateUserResult, AxiosResponse<UpdateUserResult>>('/api/v1/users/updateme', data)

  if (res.data.code !== 1) {
    throw new Error(res.data.msg || '更新失败')
  }


  // 2. 核心逻辑：只要后端 code 是 1，我们就给页面返回 updated: true
  const isUpdateSuccess = res.data.code === 1;

  // 3. 构建页面需要的标准格式，屏蔽后端 data 字段的差异
  const adaptedData: UpdateUserRes = {
    updated: isUpdateSuccess
  }
  const finalResponse: AxiosResponse<UpdateUserRes> = {
    data: adaptedData,
    status: res.status,
    statusText: res.statusText,
    headers: res.headers,
    config: res.config
  }
  return finalResponse
}

// 退出登录
export function logout(): Promise<AxiosResponse<LogoutRes>> {
  return instance.post<LogoutRes, AxiosResponse<LogoutRes>>('/api/v1/auth/logout')
}

// 获取帖子列表
export function getAllPost(page: number, size: number): Promise<AxiosResponse<PostPageResult>> {
  return instance.get<PostPageResult, AxiosResponse<PostPageResult>>('/word/post/getAll', {
    params: { page, size }
  })
}

// 点赞
export function like(postId: number): Promise<AxiosResponse<BooleanResult>> {
  return instance.get<BooleanResult, AxiosResponse<BooleanResult>>('/word/like/create', {
    params: { postId }
  })
}

// 发送验证码
export function sendCode(phone: string): Promise<AxiosResponse<StringResult>> {
  return instance.get<StringResult, AxiosResponse<StringResult>>('/word/user/code', {
    params: { phone }
  })
}

/**
 * 取消点赞
 * ✅ 消除泛型 HttpResult<boolean>，改用 BooleanResult
 */
export function cancelLike(postId: number): Promise<AxiosResponse<BooleanResult>> {
  // 强制指定两个泛型参数：<结果数据类型, 完整的响应对象类型>
  return instance.get<BooleanResult, AxiosResponse<BooleanResult>>('/word/like/cancel', {
    params: { postId }
  })
}

/**
 * 获取我的帖子
 * ✅ 消除泛型 HttpResult<PostPageData>，改用 PostPageResult
 */
export function getMyPost(page: number, size: number): Promise<AxiosResponse<PostPageResult>> {
  // 强制指定两个泛型参数
  return instance.get<PostPageResult, AxiosResponse<PostPageResult>>('/word/post/getMine', {
    params: { page, size }
  })
}


interface UploadResponse {
  code: number;
  msg: string;
  data: string; // 后端返回的相对路径 /uploads/xxx.jpg
}

export async function uploadImage(fileUri: string): Promise<string> {
  // 1. 获取内网穿透的基准地址
  const baseUrl: string = "http://你的穿透域名.cpolar.io";

  // 2. 这里推荐使用 ArkTS 的上传 API（更符合系统规范）
  // 或者继续使用你配置好的 Axios。为了方便理解，假设使用 Axios：
  let formData = new FormData();
  // 这里的处理取决于你的 Axios 拦截器设置
  formData.append('file', fileUri);

  const res: AxiosResponse<UploadResponse> = await instance.post('/api/v1/common/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });

  if (res.data.code === 1) {
    // 拼接成完整的公网可访问地址
    return baseUrl + res.data.data;
  }
  throw new Error('上传失败');
}