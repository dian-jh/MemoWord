// src/main/ets/http/Axios.ets
import axios, {
  AxiosError,
  AxiosResponse,
  InternalAxiosRequestConfig,
  AxiosRequestConfig,
  AxiosHeaders
} from '@ohos/axios'
import promptAction from '@ohos.promptAction';

export interface HttpResult<T> {
  code: number
  message: string
  data: T
}

// ======================== MOCK 专用强类型类 (消灭 ArkTS 报错) ========================
const IS_MOCK: boolean = false;

// 1. 严格实现 HttpResult 接口
class MockResult<T> implements HttpResult<T> {
  code: number = 200;
  message: string = 'success';
  data: T;
  constructor(data: T) {
    this.data = data;
  }
}

// 2. 严格实现 AxiosResponse 接口
// 注意：接口要求 headers 必须是 AxiosHeaders，config 必须是 InternalAxiosRequestConfig
class MockResponse<T> implements AxiosResponse<T> {
  data: T;
  status: number = 200;
  statusText: string = 'OK';
  headers: AxiosHeaders;
  config: InternalAxiosRequestConfig;
  request: object = new Object();

  constructor(data: T, config: InternalAxiosRequestConfig) {
    this.data = data;
    this.config = config;
    // 强制断言以匹配 AxiosResponse 的严格 Headers 要求
    this.headers = config.headers as AxiosHeaders;
  }
}

// 3. 定义拦截器专用异常类
class MockCancelError extends Error {
  mockResponse: AxiosResponse<object, object>;
  constructor(response: AxiosResponse<object, object>) {
    super('MockedRequest');
    this.mockResponse = response;
  }
}
// ===================================================================================

export const instance = axios.create({
  baseURL: 'http://192.168.31.164:5195',
  timeout: 100000
})

// 请求拦截器
instance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  // 处理 Token
  const token = AppStorage.Get('token') as string | undefined;
  if (token) {
    config.headers.set('token', token); // 推荐使用 .set 更加 ArkTS 化
  }

  return config;
}, (error: AxiosError) => {
  promptAction.showToast({ message: error.message })
  return Promise.reject(error);
});

// 响应拦截器
instance.interceptors.response.use((response: AxiosResponse<HttpResult<object>>) => {
  if (response.data.code === 200) {
    return response;
  } else {
    promptAction.showToast({ message: response.data.message })
    return Promise.reject(response.data.message)
  }
}, (error: Error) => {
  // --- 拦截器“截胡”恢复核心 ---
  if (error instanceof MockCancelError) {
    return new Promise<AxiosResponse<object, object>>((resolve) => {
      // 模拟网络延迟
      setTimeout(() => {
        resolve(error.mockResponse);
      }, 500);
    });
  }

  // 真正的网络错误处理
  if (error instanceof AxiosError) {
    promptAction.showToast({ message: error.message })
  }
  return Promise.reject(error);
});
