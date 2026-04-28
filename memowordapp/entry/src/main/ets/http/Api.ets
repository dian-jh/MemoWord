import { instance } from './Axios'
import { AxiosResponse, AxiosRequestConfig } from '@ohos/axios'

// ======================== 基础通用接口 ========================

export interface HttpResult<T> {
  code: number
  message: string
  data: T
}


// ======================== 学习统计与单词模块 (严格类型定义) ========================

// 完全对齐 C# 后端返回的单词实体
export interface StudyWord {
  id: number
  wordContent: string
  phoneticEn: string | null
  phoneticUs: string | null
  definition: string | null
  translation: string | null
  wordTags: string | null
  wordExchanges: string | null
  bncLevel: number
  frqLevel: number
  collinsLevel: number
  oxfordLevel: number
  exampleSentences: string | null
}

// 完全对齐 C# 返回的历史记录 DTO
export interface DailyStudyRecordDto {
  date: string
  learnedCount: number
  targetCount: number
  studyDuration: number
}

// 【核心修复】：将请求参数定义为 Class，以满足 ArkTS 对对象字面量的严格限制
export class SetTodayTargetRequest {
  targetCount: number
  constructor(targetCount: number) {
    this.targetCount = targetCount
  }
}

export class SetTodayLearnedCountRequest {
  learnedCount: number
  constructor(learnedCount: number) {
    this.learnedCount = learnedCount
  }
}

export class SetTodayStudyDurationRequest {
  duration: number
  constructor(duration: number) {
    this.duration = duration
  }
}

// ======================== 搜索模块 ========================

export interface SearchWordResult {
  id: number
  wordContent: string
  phoneticUs: string | null
  translation: string | null
}

// ======================== 收藏模块模型 ========================

// 11. 带有收藏状态的单词包装对象 (用于详情页和今日复习队列)
export interface WordWithFavorite {
  word: StudyWord
  isFavorite: boolean
}

// 12. 收藏夹列表模型 (对应后端的 FavoriteWordModel)
export interface FavoriteWord {
  wordId: number
  wordContent: string
  phoneticUs: string | null
  translation: string | null
  wordExchanges: string | null
  exampleSentences: string | null
  createTime: string
  // 👇 前端特有辅助字段：用于在 UI 上即时切换状态
  isFavorite: boolean
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


// --- 学习统计 API (全新极简强类型版本) ---

// 1. 获取今日目标
export async function getTodayTargetCount(): Promise<number> {
  try {
    // 显式指定所有泛型参数，AxiosResponse<数据结构, 请求配置结构>
    const response: AxiosResponse<HttpResult<number | null>, object> =
      await instance.get<HttpResult<number | null>, AxiosResponse<HttpResult<number | null>, object>, object>('/word/study/target/today');

    // 严谨的非空校验：ArkTS 推荐先验证 response 及 response.data 是否存在
    if (response && response.data) {
      const resultData = response.data.data;
      // 处理 null 的情况，确保最终返回 number
      return resultData !== null ? resultData : 0;
    }
    return 0;

  } catch (err) {
    // 严谨访问属性，确保错误消息不为空
    const errorMessage: string = err.message ?? 'Unknown Network Error';
    console.error('MemoWord_Debug', `[API] 获取目标失败: ${errorMessage}`);

    return 0;
  }
}
// 2. 设置今日目标
export async function setTodayTargetCount(targetCount: number): Promise<void> {
  console.info('MemoWord_Debug', `[API] 准备发送 POST 请求设定目标，参数 targetCount: ${targetCount}`);
  const payload = new SetTodayTargetRequest(targetCount)
  await instance.post('/word/study/target/today', payload)
}

// 3. 获取今日已学单词数
export async function getTodayLearnedCount(): Promise<number> {
  const response: AxiosResponse<HttpResult<number>> = await instance.get('/word/study/learned/today')
  return response.data.data
}

// 4. 设置今日已学单词数
export async function setTodayLearnedCount(learnedCount: number): Promise<void> {
  const payload = new SetTodayLearnedCountRequest(learnedCount)
  await instance.post('/word/study/learned/today', payload)
}

// 5. 获取今日学习时长 (分钟)
export async function getTodayStudyDuration(): Promise<number> {
  const response: AxiosResponse<HttpResult<number>> = await instance.get('/word/study/duration/today')
  return response.data.data
}

// 6. 设置今日学习时长 (分钟)
export async function setTodayStudyDuration(duration: number): Promise<void> {
  const payload = new SetTodayStudyDurationRequest(duration)
  await instance.post('/word/study/duration/today', payload)
}

// 7. 获取用户学习历史记录
export async function getLearnedHistory(): Promise<DailyStudyRecordDto[]> {
  const response: AxiosResponse<HttpResult<DailyStudyRecordDto[]>> = await instance.get('/word/study/learned/history')
  return response.data.data
}

// 8. 获取今日单词队列 (更新版：返回带收藏状态的包装对象)
export async function getTodayWordQueue(count: number): Promise<WordWithFavorite[]> {
  const response: AxiosResponse<HttpResult<WordWithFavorite[]>> = await instance.get('/word/study/today/words', {
    params: { count: count }
  })
  return response.data.data
}

// 9. 【极速搜索】边输边搜接口
export async function searchWords(keyword: string, config?: AxiosRequestConfig): Promise<SearchWordResult[]> {
  // ArkTS 严格模式下的对象合并方案：不使用 ... 展开符
  let requestConfig: AxiosRequestConfig;

  if (config) {
    requestConfig = config;
    // 如果外部传入了 config（比如带了 cancelToken），我们把 params 追加进去
    requestConfig.params = { keyword: keyword };
  } else {
    // 如果外部没有传 config，我们自己建一个包含 params 的配置
    requestConfig = {
      params: { keyword: keyword }
    };
  }

  const response: AxiosResponse<HttpResult<SearchWordResult[]>> = await instance.get(
    '/word/study/search',
    requestConfig
  );

  return response.data.data || [];
}

// 10. 获取单词详情 (更新版：返回带收藏状态的包装对象)
export async function getWordDetail(wordId: number): Promise<WordWithFavorite | null> {
  try {
    const response: AxiosResponse<HttpResult<WordWithFavorite>> = await instance.get(`/word/study/detail/${wordId}`)
    return response.data.data
  } catch (err) {
    console.error('MemoWord_Debug', `[API] 获取单词详情失败: ${wordId}`)
    return null
  }
}


// 11. 收藏/取消收藏切换
// 返回值 boolean 代表操作后的最新状态 (true: 已收藏, false: 未收藏)
export async function toggleFavorite(wordId: number): Promise<boolean> {
  const response: AxiosResponse<HttpResult<boolean>> = await instance.post(`/word/favorite/toggle/${wordId}`)
  return response.data.data
}

// 12. 获取收藏夹列表
export async function getFavoriteList(): Promise<FavoriteWord[]> {
  const response: AxiosResponse<HttpResult<FavoriteWord[]>> = await instance.get('/word/favorite/list')

  // 核心逻辑：给后端返回的数据手动注入 isFavorite = true
  // 这样你在 UI 上点击“红心”取消时，直接修改这个字段即可
  const list = response.data.data || []
  return list.map(item => {
    item.isFavorite = true
    return item
  })
}



// ======================== 搜索历史模块 ========================

// 1. 定义搜索历史专用 DTO（继承自 SearchWordResult）
export interface SearchHistoryDto extends SearchWordResult {
  createTime: string;
}

// 2. 由于后端 AddHistory 使用 [FromBody] int wordId，
// 在 ArkTS 中发送 POST 原生类型建议包装或直接传递数字（根据 Axios 插件版本确定）
// 这里为了类型严谨，直接定义 API 函数的入参类型
export async function addSearchHistory(wordId: number): Promise<boolean> {
  // 发送一个标准的 JSON 对象 { "wordId": 123 }
  // 这符合 NETSTACK 对 "object" 类型要求
  const res: AxiosResponse<BooleanResult> = await instance.post<BooleanResult>(
    '/word/study/history',
    { "wordId": wordId }
  );
  return res.data.code === 1;
}

/**
 * 获取搜索历史列表
 */
export async function getSearchHistory(): Promise<SearchHistoryDto[]> {
  const res: AxiosResponse<HttpResult<SearchHistoryDto[]>> =
    await instance.get<HttpResult<SearchHistoryDto[]>>('/word/study/history');

  // 确保返回的是数组，避免 null 导致的类型错误
  return res.data.data ?? [];
}

/**
 * 清空搜索历史
 */
export async function clearSearchHistory(): Promise<boolean> {
  const res: AxiosResponse<BooleanResult> = await instance.delete<BooleanResult, AxiosResponse<BooleanResult>>('/word/study/history');
  return res.data.code === 1;
}




// 修改密码请求体
export interface UpdatePasswordReq {
  oldPassword: string;   // 原密码
  newPassword: string;   // 新密码
  // confirmPassword: string; // 确认新密码
}
// 修改密码接口返回结果
export interface UpdatePasswordRes {
  code: number;
  msg: string;
  data?: null; // 一般改密码成功不需要返回数据，用null占位
}
//修改密码
export async function updatePassword(
  data: UpdatePasswordReq
): Promise<AxiosResponse<UpdatePasswordRes>> {
  const res: AxiosResponse<UpdatePasswordRes> = await instance.put<UpdatePasswordRes>(
    '/api/v1/users/updatepassword', // 接口路径可按你后端实际情况调整
    data
  );
  if (res.data.code !== 1) {
    throw new Error(res.data.msg || '修改密码失败');
  }
  return res;
}



// ======================== AI 模块模型定义 ========================

/**
 * 消息项定义
 */
export interface AiChatMessage {
  id: string
  role: string // 'user' | 'assistant' | 'system'
  content: string
  createTime: string
}

/**
 * 发送消息响应的业务数据 (Data 层)
 */
export interface SendMessageData {
  sessionId: string
  userMessage: AiChatMessage
  assistantMessage: AiChatMessage
}

/**
 * AI 模块专属包装类：获取消息列表返回
 * 对齐项目中 UserInfoResult 的 code/msg/data 结构
 */
export interface AiMessagesResult {
  code: number
  message: string // 保持与 AI 后端返回字段一致
  data: AiChatMessage[]
}

/**
 * AI 模块专属包装类：发送消息返回
 */
export interface SendMessageResult {
  code: number
  message: string
  data: SendMessageData
}

// 【核心修复】：为发送消息定义 Request Class，满足 ArkTS 严格对象校验
export class SendAiMessageRequest {
  content: string
  constructor(content: string) {
    this.content = content
  }
}

// ======================== AI 模块接口实现 ========================

/**
 * 获取 AI 聊天记录
 * @param sessionId 会话ID
 * @param take 获取条数
 */
export async function getAiMessages(sessionId: string, take: number = 20): Promise<AiChatMessage[]> {
  // 显式指定泛型：<返回体, 最终Axios封装体, 参数类型>
  const res: AxiosResponse<AiMessagesResult> = await instance.get<AiMessagesResult, AxiosResponse<AiMessagesResult>>(
    `/ai/sessions/${sessionId}/messages`,
    {
      params: { "take": take }
    }
  )

  // 严谨业务校验
  if (res.data.code !== 200) {
    throw new Error(res.data.message || '获取 AI 历史记录失败')
  }

  return res.data.data ?? []
}

/**
 * 发送消息给 AI 并获取回复
 * @param sessionId 会话ID
 * @param content 消息内容
 */
export async function sendAiMessage(sessionId: string, content: string): Promise<SendMessageData> {
  const payload = new SendAiMessageRequest(content)

  const res: AxiosResponse<SendMessageResult> = await instance.post<SendMessageResult, AxiosResponse<SendMessageResult>>(
    `/ai/sessions/${sessionId}/messages`,
    payload
  )

  // 严谨业务校验
  if (res.data.code !== 200) {
    throw new Error(res.data.message || 'AI 响应失败')
  }

  return res.data.data
}