import { BusinessError } from '@ohos.base';
import { AxiosResponse } from '@ohos/axios';
import {
  login,
  LoginReq,
  LoginResult
} from '../http/Api';
import { promptAction, router } from '@kit.ArkUI';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State password: string = '';
  @State isAgreeChecked: boolean = false;
  @StorageLink('token') token: string = '';

  aboutToAppear() {
    AppStorage.setOrCreate('token', '');
  }

  build() {
    Column() {
      // 返回按钮
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .margin({ top: 16, left: 20 })
        .alignSelf(ItemAlign.Start)
        .onClick(() => this.goBack());

      // 内容区
      Scroll() {
        Column({ space: 20 }) {
          // 标题
          Text('欢迎登录')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1D2129')
            .margin({ top: 20, bottom: 10 });

          // 手机号输入（用容器 + 底部边框实现）
          Column({ space: 8 }) {
            Text('账号/手机号')
              .fontSize(14)
              .fontColor('#4E5969')
              .width('100%');

            TextInput({ placeholder: '请输入账号/手机号', text: this.phone })
              .height(44)
              .fontSize(15)
              .backgroundColor(Color.Transparent)
              .onChange(v => this.phone = v);
          }
          .width('100%')
          .padding({ bottom: 8 })
          .border({ width: { bottom: 1 }, color: '#E5E6EB' });

          // 密码输入（用容器 + 底部边框实现）
          Column({ space: 8 }) {
            Text('密码')
              .fontSize(14)
              .fontColor('#4E5969')
              .width('100%');

            TextInput({ placeholder: '请输入密码', text: this.password })
              .type(InputType.Password)
              .height(44)
              .fontSize(15)
              .backgroundColor(Color.Transparent)
              .onChange(v => this.password = v);
          }
          .width('100%')
          .padding({ bottom: 8 })
          .border({ width: { bottom: 1 }, color: '#E5E6EB' });

          // 登录按钮
          Button('立即登录')
            .width('100%')
            .height(44)
            .backgroundColor(this.isAgreeChecked ? '#0066CC' : '#C9CDD4')
            .fontColor(Color.White)
            .fontSize(16)
            .borderRadius(8)
            .margin({ top: 20 })
            .enabled(this.isAgreeChecked)
            .onClick(async () => await this.handleLogin());

          // 注册按钮
          Button('注册账号')
            .width('100%')
            .height(44)
            .backgroundColor(Color.White)
            .fontColor('#0066CC')
            .fontSize(16)
            .border({ width: 1, color: '#0066CC', radius: 8 })
            .margin({ top: 12 })
            .onClick(() => this.goToRegister());

          // 协议勾选区域
          Row({ space: 8 }) {
            Checkbox({ name: 'agree' })
              .width(16)
              .height(16)
              .selectedColor('#0066CC')
              .onChange(v => this.isAgreeChecked = v);

            Text('登录即表示已同意')
              .fontSize(12)
              .fontColor('#86909C');

            Text('《用户使用协议》')
              .fontSize(12)
              .fontColor('#0066CC')
              .onClick(() => {
                promptAction.showToast({ message: '协议页面开发中' });
              });
          }
          .margin({ top: 16 })
          .justifyContent(FlexAlign.Center);
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 40 });
      }
      .layoutWeight(1);

      // 底部品牌
      Column({ space: 8 }) {
        Image($r('app.media.ic_logo'))
          .width(36)
          .height(36);
        Text('快速记单词神器')
          .fontSize(16)
          .fontColor('#4E5969')
          .fontWeight(FontWeight.Medium);
      }
      .margin({ bottom: 24 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  // 登录逻辑
  private async handleLogin(): Promise<void> {
    if (!this.phone.trim() || !this.password.trim()) {
      promptAction.showToast({ message: '账号或密码不能为空' });
      return;
    }

    try {
      const param: LoginReq = {
        account: this.phone.trim(),
        password: this.password.trim()
      };
      const res: AxiosResponse<LoginResult> = await login(param);
      const result: LoginResult = res.data;

      if (result.code === 1 && result.data) {
        AppStorage.set('token', result.data.accessToken);
        promptAction.showToast({ message: '登录成功' });
        this.goToIndex();
      } else {
        promptAction.showToast({ message: result.msg || '登录失败，请检查账号密码' });
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error('登录异常：', error.message);
      promptAction.showToast({ message: '网络异常，请稍后重试' });
    }
  }

  // 跳转首页
  private goToIndex(): void {
    router.replaceUrl({ url: 'pages/Index' })
      .catch((err: BusinessError) => {
        console.error('跳转首页失败：', err.message);
        promptAction.showToast({ message: '页面跳转失败' });
      });
  }

  // 跳转注册
  private goToRegister(): void {
    router.pushUrl({ url: 'pages/RegisterPage' })
      .catch((err: BusinessError) => {
        console.error('跳转注册页失败：', err.message);
        promptAction.showToast({ message: '注册页面跳转失败' });
      });
  }

  // 返回
  private goBack(): void {
    router.back();
  }
}

// 样式定义
@Extend(Button)
function buttonStyle1(bgColor: Color, fontColor: Color) {
  .type(ButtonType.Normal)
  .fontSize(14)
  .fontWeight(FontWeight.Medium)
  .borderWidth(1)
  .borderRadius(5)
  .backgroundColor(bgColor)
  .fontColor(fontColor)
}

@Extend(Image)
function iconStyle() {
  .width(24)
  .height(24)
}

@Extend(TextInput)
function inputStyle() {
  .height(40)
  .layoutWeight(1)
  .fontSize(14)
  .backgroundColor(Color.Transparent)
}

@Styles
function letterIconStyle() {
  .width(24)
  .height(24)
}

@Styles
function loginBoxStyle() {
  .width('90%')
  .height('45%')
  .backgroundColor(Color.White)
  .borderRadius(20)
  .padding(20)
}

@Styles
function loginStyle() {
  .width('100%')
  .height('100%')
  .backgroundImage($r("app.media.img_login_bg"))
  .backgroundImageSize({ width: '100%', height: '100%' })
}
