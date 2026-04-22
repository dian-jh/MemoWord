import { instance } from "./Axios";

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

//获取验证码
export function sendCode(phone: string) {
  return instance.get('/word/user/code', { params: { phone: phone } });
}

// 登录
export function login(phone: string, code: string) {
  return instance.post('/word/user/login', new LoginBean(phone, code));
}

//获取全部打卡列表
export function getAllPost(page: number, size: number) {
  return instance.get('/word/post/getAll', { params: { page: page, size: size } })
}

//点赞
export function like(postId: number) {
  return instance.get('/word/like/create', { params: { postId: postId } })
}

//取消点赞
export function cancelLike(postId: number) {
  return instance.get('/word/like/cancel', { params: { postId: postId } })
}

//获取登录用户信息
export function info() {
  return instance.get('/word/user/info')
}

//获取我的登录打卡记录
export function getMyPost(page: number, size: number) {
  return instance.get('/word/post/getMine', { params: { page: page, size: size } })
}

export interface PostCard {
  rightCount: number;
  answeredCount: number;
  timeUsed: number;
}

export function createPost(post: PostCard) {
  return instance.post('/word/post/create', post)
}

class LoginBean {
  phone: string;
  code: string;

  constructor(phone: string, code: string) {
    this.phone = phone;
    this.code = code;
  }
}

// 新加
// 学习情况统计
export function getStatisticsHistory() {
  return instance.get<ApiResponse<DailyStatistics[]>>('/word/stat/getHistory')
}

export interface DailyStatistics {
  learnedCount: number;
  timeUsed: number;
  targetCount: number;
  statDate?: string;     // 这里的问号保留，因为上传时可能不需要日期
  id?: string;           // 对应你 Model 里的 id
  userId?: string;       // 对应你 Model 里的 userId
}

export function updateDailyStatistics(stats: DailyStatistics) {
  return instance.post<ApiResponse<null>>('/word/stat/update', stats);
}