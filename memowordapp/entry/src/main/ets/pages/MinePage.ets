import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { info } from '../http/Api';
import { AxiosResponse } from "@ohos/axios";


interface UserInfo {
  nickname: string,
  avatarUrl: string
}


interface ApiResponse {
  data: UserInfo
}

@Component
export struct MinePage {
  @StorageLink('token') @Watch('onTokenChange') token: string = ''
  @State userInfo: UserInfo = {
    nickname: '',
    avatarUrl: ''
  };

  async onTokenChange() {
    if (this.token) {
      let response: AxiosResponse<ApiResponse> = await info()
      this.userInfo = response.data.data;
    } else {
      this.userInfo = {
        nickname: '',
        avatarUrl: ''
      }
    }
  }

  async aboutToAppear() {
    if (this.token) {
      let response: AxiosResponse<ApiResponse> = await info()
      this.userInfo = response.data.data;
    }
  }

  build() {
    Stack() {
      Column() {
        Image(this.token ? this.userInfo.avatarUrl : $r('app.media.img_avatar'))
          .width(100)
          .height(100)
          .borderRadius(50)
          .margin({ top: 120 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/LoginPage' })
          })

        Text(this.token ? this.userInfo.nickname : '暂未登录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ top: 20 })

        if (!this.token) {
          Text('请点击头像登录')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .height('50%')
      .backgroundImage(this.token ? this.userInfo.avatarUrl : $r('app.media.img_avatar'))
      .backgroundImageSize({ height: '100%', width: '100%' })
      .backgroundBlurStyle(BlurStyle.Regular)

      Column({ space: 10 }) {
        // 1. 打卡记录（如果也想直接跳转，可以同样去掉判断）
        this.mineItemBuilder($r('app.media.ic_mine_card'), '打卡记录', () => {
          router.pushUrl({ url: 'pages/PostHistoryPage' })
        })
        Divider()

        // 【修改点】：去掉 if(this.token) 逻辑，直接执行跳转
        this.mineItemBuilder($r('app.media.ic_mine_card'), '生词本', () => {
          router.pushUrl({ url: 'pages/RawWordPage' })
        })
        Divider()

        // 2. 原有的检查更新
        this.mineItemBuilder($r('app.media.ic_mine_update'), '检查更新', () => {
          promptAction.showToast({ message: '已是最新' })
        })
        Divider()
      }
      .width('100%')
      .height('60%')
      .offset({ y: '40%' })
      .borderRadius({ topLeft: 50, topRight: 50 })
      .backgroundColor(Color.White)
      .padding(30)

    }.width('100%')
    .height('100%')
    .alignContent(Alignment.Top)
  }

  @Builder
  mineItemBuilder(icon: Resource, title: string, callback?: () => void) {
    Row({ space: 10 }) {
      Image(icon)
        .width(24)
        .height(24)
      Text(title)
        .fontSize(16)
        .height(24)
        .fontWeight(FontWeight.Medium)
      Blank()
      Image($r('app.media.ic_arrow_right'))
        .width(24)
        .height(24)
    }.width('100%')
    .height(40)
    .onClick(() => {
      callback?.() // 使用可选链安全调用
    })
  }
}