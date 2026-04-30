//
//
//
// import axios, {
//   AxiosError,
//   AxiosResponse,
//   InternalAxiosRequestConfig,
//   AxiosRequestConfig,
//   AxiosHeaders
// } from '@ohos/axios'
// import promptAction from '@ohos.promptAction';
// import { mockWords } from '../mock/MockData';
//
// export interface HttpResult<T> {
//   code: number
//   message: string
//   data: T
// }
//
// const IS_MOCK: boolean = false;
//
// // ======================== MOCK 专用类 (保持不变) ========================
// class MockResult<T> implements HttpResult<T> {
//   code: number = 200;
//   message: string = 'success';
//   data: T;
//   constructor(data: T) {
//     this.data = data;
//   }
// }
//
// class MockResponse<T> implements AxiosResponse<T> {
//   data: T;
//   status: number = 200;
//   statusText: string = 'OK';
//   headers: AxiosHeaders;
//   config: InternalAxiosRequestConfig;
//   request: object = new Object();
//   constructor(data: T, config: InternalAxiosRequestConfig) {
//     this.data = data;
//     this.config = config;
//     this.headers = config.headers as AxiosHeaders;
//   }
// }
//
// class MockCancelError extends Error {
//   mockResponse: AxiosResponse<object, object>;
//   constructor(response: AxiosResponse<object, object>) {
//     super('MockedRequest');
//     this.mockResponse = response;
//   }
// }

// // ======================== 实例配置 ========================
// export const instance = axios.create({
//   // 注意：确保这里的 IP 和端口与你后端一致，如果是预览器访问电脑后端，建议用真实 IP
//   baseURL: 'http://127.0.0.1:8080',
//   timeout: 10000
// })
//
// // 请求拦截器
// instance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
//   const token = AppStorage.Get('token') as string | undefined;
//
//   // ✅ 正确适配你的 Java 后端
//   if (token) {
//     config.headers.set('Authorization', 'Bearer ' + token);
//   }
//
//   // ✅ MOCK 已经关闭，不会再拦截
//   return config;
// }, (error: AxiosError) => {
//   return Promise.reject(error);
//
// });
//
// // 响应拦截器 (重点修改：适配纯业务数据返回)
// instance.interceptors.response.use((response: AxiosResponse) => {
//   // 只要 HTTP 状态码是 2xx，就直接返回数据
//   if (response.status >= 200 && response.status < 300) {
//     return response;
//   } else {
//     return Promise.reject('请求失败');
//   }
// }, (error: Error) => {
//   if (error instanceof MockCancelError) {
//     return new Promise<AxiosResponse<object, object>>((resolve) => {
//       setTimeout(() => resolve(error.mockResponse), 500);
//     });
//   }
//   if (error instanceof AxiosError) {
//     promptAction.showToast({ message: "网络请求错误: " + error.message })
//   }
//   return Promise.reject(error);
// });
//
//
//















import axios, {
  AxiosError,
  AxiosResponse,
  InternalAxiosRequestConfig,
  AxiosHeaders
} from '@ohos/axios'
import promptAction from '@ohos.promptAction';

// ... HttpResult 等接口保持不变 ...
export interface HttpResult<T> {
  code: number
  message: string
  data: T
}

const IS_MOCK: boolean = false;

// ======================== MOCK 专用类 (保持不变) ========================
class MockResult<T> implements HttpResult<T> {
  code: number = 200;
  message: string = 'success';
  data: T;
  constructor(data: T) {
    this.data = data;
  }
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

// ======================== 实例配置 ========================
export const instance = axios.create({
  // 💡 重要提示：如果你是在【真机】或【模拟器】运行，127.0.0.1 是访问不到电脑后端的
  // 请打开 CMD 输入 ipconfig 查看你电脑的局域网 IP，例如 192.168.1.5
  // baseURL: 'http://192.168.31.227:8080',
  baseURL: 'http://2bf2dc5e.r21.cpolar.top',

  timeout: 10000

})

// 请求拦截器
// 2. 请求拦截器：强制类型指定，适配后端 Header
instance.interceptors.request.use((config: InternalAxiosRequestConfig): InternalAxiosRequestConfig => {
  // 强制指定 token 为 string 类型
  const token: string = AppStorage.get('token') as string;

  if (token) {
    // ✅ 必须改为 'token'，因为你的后端 JwtAuthenticationFilter 只执行 getHeader("token")
    // ✅ 必须去掉 'Bearer '，因为你的后端 JwtUtil.parseJWT 直接解析该字符串，带了前缀会报错
    config.headers.set('token', token);
    console.info("发送请求路径: " + config.url + " | 携带 Token: 已携带");
  } else {
    console.warn("发送请求路径: " + config.url + " | 携带 Token: 缺失!!!");
  }

  return config;
}, (error: AxiosError): Promise<AxiosError> => {
  return Promise.reject(error);
});

// 3. 响应拦截器：彻底消除 any，强化错误捕获
instance.interceptors.response.use((response: AxiosResponse): AxiosResponse => {
  // 打印成功日志，注意 status 转为字符串避免 ArkTS 警告
  console.info("[Axios] 响应成功: " + response.config.url + " | Status: " + response.status.toString());
  return response;
}, (error: AxiosError): Promise<AxiosError> => {

  // 记录错误消息
  console.error("[Axios] 错误详情: " + error.message);

  if (error.response) {
    // 情况 A：服务器返回了错误码 (401, 403, 500 等)
    const status: string = error.response.status.toString();
    const dataString: string = JSON.stringify(error.response.data);

    console.error("[Axios] 后端状态码: " + status + " | 数据: " + dataString);

    if (error.response.status === 401) {
      promptAction.showToast({ message: '登录已过期，请重新登录' });
    } else if (error.response.status === 403) {
      // 403 通常是 Header 名字写错或 Token 没带上，或是后端 Security 拒绝
      promptAction.showToast({ message: '权限不足或鉴权失败(403)' });
    }
  } else if (error.request) {
    // 情况 B：请求发出了，但没收到响应 (IP 不对、后端挂了、网络隔离)
    console.error("[Axios] 未收到服务器响应，请确认电脑 IP 是否为: 222.24.72.24");
    promptAction.showToast({ message: '网络异常，请检查服务器连接' });
  } else {
    // 情况 C：设置请求时触发了错误
    console.error("[Axios] 请求配置错误: " + error.message);
  }

  return Promise.reject(error);
});