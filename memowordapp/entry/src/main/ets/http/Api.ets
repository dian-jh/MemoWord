import { AxiosResponse } from '@ohos/axios'
import { instance } from './Axios'

// ======================== 基础通用接口 ========================

export interface HttpResult<T> {
  code: number
  message: string
  data: T
}

// ======================== 用户与帖子模块接口 (保持原有) ========================

export interface PostCard {
  rightCount: number
  answeredCount: number
  timeUsed: number
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

export interface UserProfile {
  nickname: string
  avatarUrl: string
}

export interface PostPageData {
  records: PostRecord[]
  total: number
}

class LoginBean {
  phone: string
  code: string
  constructor(phone: string, code: string) {
    this.phone = phone
    this.code = code
  }
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

// ======================== API 请求方法 ========================

// --- 用户与帖子 API (保持原有) ---
export function sendCode(phone: string): Promise<AxiosResponse<HttpResult<string>>> {
  return instance.get('/word/user/code', { params: { phone: phone } })
}

export function login(phone: string, code: string): Promise<AxiosResponse<HttpResult<string>>> {
  return instance.post('/word/user/login', new LoginBean(phone, code))
}

export function getAllPost(page: number, size: number): Promise<AxiosResponse<HttpResult<PostPageData>>> {
  return instance.get('/word/post/getAll', { params: { page: page, size: size } })
}

export function like(postId: number): Promise<AxiosResponse<HttpResult<boolean>>> {
  return instance.get('/word/like/create', { params: { postId: postId } })
}

export function cancelLike(postId: number): Promise<AxiosResponse<HttpResult<boolean>>> {
  return instance.get('/word/like/cancel', { params: { postId: postId } })
}

export function info(): Promise<AxiosResponse<HttpResult<UserProfile>>> {
  return instance.get('/word/user/info')
}

export function getMyPost(page: number, size: number): Promise<AxiosResponse<HttpResult<PostPageData>>> {
  return instance.get('/word/post/getMine', { params: { page: page, size: size } })
}

export function createPost(post: PostCard): Promise<AxiosResponse<HttpResult<boolean>>> {
  return instance.post('/word/post/create', post)
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

// 8. 获取今日单词队列
export async function getTodayWordQueue(count: number): Promise<StudyWord[]> {
  const response: AxiosResponse<HttpResult<StudyWord[]>> = await instance.get('/word/study/today/words', {
    params: { count: count }
  })
  return response.data.data
}
