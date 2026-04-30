import { router, promptAction } from '@kit.ArkUI';
import { register, RegisterReq, RegisterResult } from '../http/Api';
import { AxiosResponse } from '@ohos/axios';
interface BackendError {
  code: number;
  msg: string;
}

interface GeneratedTypeLiteralInterface_2 {
  data: BackendError;
}

interface GeneratedTypeLiteralInterface_1 {
  response?: GeneratedTypeLiteralInterface_2;
}

@Entry
@Component
struct RegisterPage {
  @State account: string = '';
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isSubmitting: boolean = false;
  @State isAccountError: boolean = false;

  async handleRegister() {
    // 前置校验
    if (!this.account || this.account.length < 11) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    if (!this.username || this.username.trim().length < 2) {
      promptAction.showToast({ message: '昵称至少2位' });
      return;
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码至少6位' });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }

    this.isSubmitting = true;

    try {
      const reqParam: RegisterReq = {
        account: this.account,
        username: this.username,
        password: this.password
      };
      const response: AxiosResponse<RegisterResult> = await register(reqParam);
      const res: RegisterResult = response.data;

      if (res.code === 1) {
        promptAction.showToast({ message: '注册成功，请登录' });
        setTimeout(() => {
          router.back();
        }, 1500);
      } else {
        if (res.code === 100001 || res.msg === "100001") {
          promptAction.showToast({ message: '该账号已注册，请直接登录' });
        } else {
          const msg: string = res.msg !== null ? res.msg : '注册失败';
          promptAction.showToast({ message: msg });
        }
      }
    } catch (e) {
      const errorObj = e as GeneratedTypeLiteralInterface_1;
      const responseObj = errorObj.response;
      if (responseObj) {
        const backendError: BackendError = responseObj.data as BackendError;
        if (backendError) {
          promptAction.showToast({ message: backendError.msg });
        } else {
          promptAction.showToast({ message: '服务器返回异常' });
        }
      } else {
        promptAction.showToast({ message: '网络连接异常' });
      }
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Scroll() { // 使用 Scroll 防止键盘遮挡
      Column({ space: 0 }) { // space 设为 0，由各字段自行控制 margin-bottom
        // 标题
        Text('创建新账号')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 0, bottom: 80 })

        // 1. 手机号字段
        Column({ space: 4 }) {
          TextInput({ placeholder: '请输入手机号', text: this.account })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .width('90%')
            .border({ width: 1, color: this.isAccountError ? Color.Red : '#DCDCDC' })
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange(v => {
              this.account = v;
              const reg = /^1[3-9]\d{9}$/;
              this.isAccountError = !reg.test(v);
            })
          if (this.isAccountError) {
            Text('请输入正确的11位手机号')
              .fontSize(12)
              .fontColor(Color.Red)
              .margin({ left: 10, top: 2 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 20 })

        // 2. 昵称字段
        Column() {
          TextInput({ placeholder: '请输入用户昵称', text: this.username })
            .width('90%')
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange(v => this.username = v)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 20 })

        // 3. 密码字段
        Column() {
          TextInput({ placeholder: '设置密码', text: this.password })
            .type(InputType.Password)
            .maxLength(16)
            .width('90%')
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange(v => this.password = v)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 20 })

        // 4. 确认密码字段
        Column() {
          TextInput({ placeholder: '确认密码', text: this.confirmPassword })
            .type(InputType.Password)
            .maxLength(16)
            .width('90%')
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .onChange(v => this.confirmPassword = v)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 30 }) // 与按钮间距稍大

        // 注册按钮
        Button(this.isSubmitting ? '正在注册...' : '立即注册')
          .width('90%')
          .height(50)
          .borderRadius(25)
          .backgroundColor(this.isSubmitting ? '#CCCCCC' : '#007AFF')
          .fontColor(Color.White)
          .enabled(!this.isSubmitting)
          .onClick(() => this.handleRegister())

        // 返回登录链接
        Text('已有账号？去登录')
          .fontColor(Color.Blue)
          .margin({ top: 20, bottom: 30 })
          .onClick(() => router.back())
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
