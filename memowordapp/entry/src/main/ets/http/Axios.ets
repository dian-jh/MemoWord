// src/main/ets/http/Axios.ets
import axios, {
  AxiosError,
  AxiosResponse,
  InternalAxiosRequestConfig,
  AxiosRequestConfig,
  AxiosHeaders
} from '@ohos/axios'
import promptAction from '@ohos.promptAction';
import { StorageKeys } from '../store/GlobalState';

// 1. 增强 HttpResult 接口定义
// 兼容后端可能存在的不规范字段，将 message 和 msg 声明为可选
export interface HttpResult<T> {
  code: number
  message?: string  // 设为可选，防止后端未返回此字段
  msg?: string      // 兼容旧接口可能存在的 msg 字段
  data: T
}


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
    this.headers = config.headers as AxiosHeaders;
  }
}

class MockCancelError extends Error {
  mockResponse: AxiosResponse<object, object>;
  constructor(response: AxiosResponse<object, object>) {
    super('MockedRequest');
    this.mockResponse = response;
  }
}
// ===================================================================================

export const instance = axios.create({
  baseURL: 'http://10.33.86.233:5000',
  timeout: 100000
})

// 请求拦截器
instance.interceptors.request.use((config: InternalAxiosRequestConfig): InternalAxiosRequestConfig => {
  // 强制指定 token 为 string 类型
  const token: string = AppStorage.get('token') as string;

  if (token) {
    config.headers.set('token', token);
    console.info("发送请求路径: " + config.url + " | 携带 Token: 已携带");
  } else {
    console.warn("发送请求路径: " + config.url + " | 携带 Token: 缺失!!!");
  }

  return config;
}, (error: AxiosError): Promise<AxiosError> => {
  return Promise.reject(error);
});


// 响应拦截器
instance.interceptors.response.use((response: AxiosResponse<HttpResult<object>>) => {
  const code: number = response.data.code;

  // 1. 兼容你后端的成功状态码 (200 或 1，如果你的后端全改成了 200，删掉 code === 1 即可)
  if (code === 200 || code === 1) {
    return response;
  } else {
    // 2. 终极防御：提取错误信息并强制转换为 String 类型
    // 使用可选链 (?.) 和空值合并 (??) 确保一定能拿到合法字符串
    const errorMsg: string = String(response.data?.message ?? response.data?.msg ?? '业务处理失败');

    // 这行代码现在绝对安全，不会再引发 Parameter error
    promptAction.showToast({ message: errorMsg });

    // 3. 规范错误抛出：抛出标准的 Error 对象，方便外层 catch (err as Error) 进行强类型捕获
    return Promise.reject(new Error(errorMsg));
  }
}, (error: Error) => {
  // --- 拦截器“截胡”恢复核心 ---
  if (error instanceof MockCancelError) {
    return new Promise<AxiosResponse<object, object>>((resolve) => {
      setTimeout(() => {
        resolve(error.mockResponse);
      }, 500);
    });
  }

  // --- 真正的 HTTP 网络错误处理 (例如 401, 404, 502 等) ---
  let networkErrorMsg: string = '网络异常，请稍后再试';

  if (error instanceof AxiosError) {
    // 如果后端在 HTTP 错误状态码时也返回了 HttpResult 格式的 JSON，尝试解析它
    const errorData = error.response?.data as HttpResult<object> | undefined;

    if (errorData && (errorData.message || errorData.msg)) {
      networkErrorMsg = String(errorData.message ?? errorData.msg);
    } else {
      // 提取 Axios 的底层报错信息
      networkErrorMsg = String(error.message ?? '网络连接失败');
    }
  }

  promptAction.showToast({ message: networkErrorMsg });
  return Promise.reject(error);
});