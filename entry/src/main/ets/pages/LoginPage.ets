import { BusinessError } from '@ohos.base';
import { AxiosResponse } from '@ohos/axios'
import {
  login,
  LoginReq,
  LoginRes,
  PostCard,
  // createPost,   // 记得检查是否导入了打卡函数
  LoginResult,   // ✅ 新增导入这个专门的返回包装类
  createPost
} from '../http/Api'

import { promptAction, router } from '@kit.ArkUI'
import emitter from '@ohos.events.emitter';

@Entry
@Component
struct LoginPage {
  @State phone: string = "13800000000"
  @State password: string = "123456"
  @StorageLink('token') token: string = ''
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;


  aboutToAppear() {
    console.info("初始化 AppStorage");

    AppStorage.setOrCreate('token', '');
    AppStorage.setOrCreate('currentTabIndex', 0);
  }
  build() {


    Column() {
      Image($r("app.media.ic_back"))
        .width(25).height(25)
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20, top: 10 })
        .onClick(() => this.handleBack())

      Blank()

      Column() {
        Text('欢迎登陆').fontSize(22).fontColor(Color.Black).fontWeight(FontWeight.Bold)

        Row() {
          Image($r('app.media.ic_phone')).letterIconStyle()
          TextInput({ placeholder: "请输入账号/手机号码", text: this.phone })
            .inputStyle()
            .onChange((v: string) => this.phone = v)
        }.margin({ top: 30 })
        Divider().color(Color.Black)

        Row() {
          Image($r('app.media.ic_code')).iconStyle()
          TextInput({ placeholder: "请输入密码", text: this.password })
            .type(InputType.Password)
            .inputStyle()
            .onChange((v: string) => this.password = v)
        }.margin({ top: 20 })
        Divider().margin({ right: 120 }).color(Color.Black)

        Button('立即登陆')
          .width('100%')
          .buttonStyle1(Color.Black, Color.White)
          .margin({ top: 50 })
          .onClick(async () => {
            if (!this.phone || !this.password) {
              promptAction.showToast({ message: '账号或密码不能为空' });
              return;
            }

            try {
              const loginParam: LoginReq = { account: this.phone, password: this.password };
              const response: AxiosResponse<LoginResult> = await login(loginParam);
              const httpResult: LoginResult = response.data;

              if (httpResult.code === 1 && httpResult.data) {
                console.info("登录逻辑：成功获取 Token");

                // 1. 存储 Token
                AppStorage.set('token', httpResult.data.accessToken);
                console.info("toke:"+httpResult.data.accessToken+"///")
                promptAction.showToast({ message: '登录成功' });

                // 2. 执行打卡逻辑 (注意：这里绝对不要加 await，且要把逻辑包裹在 setTimeout 里确保它在下一个事件循环运行)
                setTimeout(() => {
                  this.handleAutoPost();
                }, 0);

                // 3. 立即执行跳转，不再等待任何后台逻辑
                console.info("准备执行跳转流程");
                this.handleBack();

              } else {
                promptAction.showToast({ message: httpResult.msg || '登录失败' });
              }
            } catch (err) {
              // 处理 ArkTS 的 catch (e) 报错，使用类型断言
              const error = err as BusinessError;
              console.error("登录点击事件捕获到异常:", error.message);
              // 如果是因为 handleAutoPost 崩了带累了这里，我们也尝试强制跳转
              this.handleBack();
            }
          })

        Button('注册账号')
          .width('100%') // 修正：原代码中 100% 需加引号
          .buttonStyle1(Color.Black, Color.White)
          .margin({ top: 10 })
          .onClick(() => {
            // 逻辑：跳转到注册页面
            // 建议使用 router.pushUrl 这样用户在注册页点返回还能回到登录页
            console.info("准备跳转至注册页面");

            try {
              router.pushUrl({
                url: "pages/RegisterPage" // ⚠️ 请确保你的注册页面路径填写正确
              }, router.RouterMode.Standard, (err) => {
                if (err) {
                  console.error(`跳转注册页失败, code is ${err.code}, message is ${err.message}`);
                  promptAction.showToast({ message: '页面跳转失败' });
                }
              })
            } catch (error) {
              console.error("Router push 异常: " + JSON.stringify(error));
            }
          })












        Row() {
          Text('登陆即表示已同意').fontSize(10).fontColor('#546B9D')
          Text('《用户使用协议》').fontSize(10).fontColor('#00B3FF')
        }.margin({ top: 20 })
      }.loginBoxStyle()

      Row({ space: 10 }) {
        Image($r('app.media.ic_logo')).width(36).height(36)
        Text('快速记单词神器').fontColor('#546B9D').fontWeight(FontWeight.Bold).fontSize(20)
      }.margin({ top: 70 })

      // Text('Developed by Atguigu').fontSize(12).margin(20).fontColor('#546B9D')
    }.loginStyle()
  }



  // 修改后的 handleAutoPost，极其卑微的静默处理
  private async handleAutoPost(): Promise<void> {
    console.info("===== 后台打卡任务开始 =====");
    try {
      // 100001 错误通常发生在直接进入登录页时没有参数
      // 我们用 try 包裹这行最危险的代码
      let params: Record<string, number> | undefined;
      try {
        params = router.getParams() as Record<string, number>;
      } catch (e) {
        console.warn("路由栈中无参数可获取");
      }

      if (!params || params['rightCount'] === undefined) {
        console.info("无打卡数据，跳过自动打卡");
        return;
      }

      await createPost({
        rightCount: params['rightCount'],
        answeredCount: params['answeredCount'],
        timeUsed: params['timeUsed']
      });

      emitter.emit({ eventId: 1 });
      AppStorage.set('currentTabIndex', 1);
      console.info("后台打卡成功");
    } catch (e) {
      const err = e as BusinessError;
      console.warn("后台打卡静默失败:", err.message);
    }
  }


  private handleBack(): void {
    console.info("开始执行 handleBack");
    // 强制跳转回首页，不论当前栈是什么情况
    router.replaceUrl({
      url: 'pages/Index'
    }).then(() => {
      console.info("路由跳转指令发送成功");
    }).catch((err: BusinessError) => {
      console.error("路由跳转失败: ", err.message);
      // 最后的保底尝试
      router.back();
    });
  }


}

// --- 样式定义保持不变 ---
@Extend(Button)
function buttonStyle1(bgColor: Color, fontColor: Color) {
  .type(ButtonType.Normal).fontSize(14).fontWeight(FontWeight.Medium)
  .borderWidth(1).borderRadius(5).backgroundColor(bgColor).fontColor(fontColor)
}

@Extend(Image)
function iconStyle() { .width(24).height(24) }

@Extend(TextInput)
function inputStyle() { .height(40).layoutWeight(1).fontSize(14).backgroundColor(Color.Transparent) }

@Styles function letterIconStyle() { .width(24).height(24) }

@Styles function loginBoxStyle() {
  .width('90%').height('45%').backgroundColor(Color.White).borderRadius(20).padding(20)
}

@Styles function loginStyle() {
  .width('100%').height('100%').backgroundImage($r("app.media.img_login_bg"))
  .backgroundImageSize({ width: '100%', height: '100%' })
}








