import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { info, AuthUserInfo, updateTargetWords,setTodayTargetCount } from '../http/Api';
import { AxiosResponse } from "@ohos/axios";
import { StorageKeys } from '../store/GlobalState';

@Component
export struct MinePage {
  @StorageLink('token') @Watch('onTokenChange') token: string = ''
  @StorageLink('temp_username') tempName :string =''
  // ✅ 新增：监听全局刷新信号。一旦这个值改变，就会触发刷新
  @StorageProp('needRefreshMine') @Watch('onSignalChange') refreshSignal: number = 0

  @StorageLink(StorageKeys.TOTAL_GOAL) todayTarget: number = 0;

  @State userInfo: AuthUserInfo = {
    id: '',
    username: '',
    account: '',
    avatarUrl: '',
    createTime:'',
    targetWords:0
  };
  onSignalChange() {
    console.info("MinePage: 感知到信号变化，新值为: " + this.refreshSignal);
    this.refreshData();
  }

  // ✅ 优化后的刷新方法
  async refreshData() {
    if (this.token) {
      console.info("MinePage: 开始准备拉取数据...");

      // 正确的 setTimeout 语法
      setTimeout(async () => {
        try {
          let response: AxiosResponse<AuthUserInfo> = await info();
          if (response.data) {
            this.userInfo = response.data;
            console.info("MinePage: 数据刷新成功，最新用户名: " + this.userInfo.username);

            AppStorage.SetOrCreate("temp_username",'')
          }
        } catch (e) {
          console.error("MinePage: 刷新请求失败，请检查网络或Token");
        }
      }, 1); // 延迟 500 毫秒执行
    } else {
      console.warn("MinePage: Token 为空，跳过刷新");
    }
  }


  async onTokenChange() {
    if (this.token) {
      await this.refreshData();
    } else {
      this.resetUserInfo();
    }
  }

  async aboutToAppear() {
    await this.refreshData();
  }

  resetUserInfo() {
    this.userInfo = { id: '', username: '', account: '', avatarUrl: '' ,createTime:'',targetWords:0}
  }


  // 在 struct 内部
  customTargetDialog: CustomDialogController = new CustomDialogController({
    builder: TargetInputDialog({
      confirm: (val: string) => {
        this.saveTarget(val)
      }
    }),
    alignment: DialogAlignment.Center, // 屏幕中心弹出
    autoCancel: true,
    customStyle: true // 使用组件定义的圆角和背景
  })

  // 保存目标的逻辑方法
  private async  saveTarget(num: string) {
    let targetNum: number = parseInt(num);

    try {
      // 1. 同步给用户预设目标表
      await updateTargetWords(targetNum);

      // 2. ✅ 同步给今日统计表（解决 StudyIndexPage 不刷新的关键）
      await setTodayTargetCount(targetNum);

      // 3. 更新本地 UI 和全局存储
      this.userInfo.targetWords = targetNum;
      this.todayTarget = targetNum;

      promptAction.showToast({
        message: '修改成功，当前每日目标单词数为：' + targetNum
      });
    } catch (error) {
      console.error("同步失败", JSON.stringify(error));
      promptAction.showToast({ message: '修改失败，请检查网络' });
    }
  }



  build() {
    Stack() {
      Column() {
        // 头像部分
        Image(this.token && this.userInfo.avatarUrl ? this.userInfo.avatarUrl : $r('app.media.img_avatar'))
          .width(150)
          .height(150)
          .borderRadius(75) // ✅ 改为 75（150的一半）保证正圆
          .margin({ top: 50 })
          .onClick(() => {
            if (!this.token) {
              router.pushUrl({ url: 'pages/LoginPage' })
            }
          })

        Text(this.token? this.userInfo.username : '暂未登录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .margin({ top: 20 })

        if (!this.token) {
          Text('请点击头像登录')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.Black)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .height('50%')
      .backgroundImage(this.token && this.userInfo.avatarUrl ? this.userInfo.avatarUrl : $r('app.media.img_avatar'))
      .backgroundImageSize({ height: '100%', width: '100%' })
      .backgroundBlurStyle(BlurStyle.Regular)

      Column({ space: 10 }) {


        this.mineItemBuilder($r('app.media.ic_mine_card'), '修改每日目标', () => {
          if (this.token) {
            promptAction.showActionMenu({
              title: `当前每日目标单词数为 ${this.userInfo?.targetWords || 20}`,              buttons: [
                { text: '20个 (轻松)', color: '#000000' },
                { text: '50个 (标准)', color: '#000000' },
                { text: '100个 (挑战)', color: '#000000' },
                { text: '自定义数值', color: '#666666' }
              ]
            }).then((data: promptAction.ActionMenuSuccessResponse) => {
              // 严格根据 index 判断
              if (data.index === 0) {
                this.saveTarget('20')
              } else if (data.index === 1) {
                this.saveTarget('50')
              } else if (data.index === 2) {
                this.saveTarget('100')
              } else if (data.index === 3) {
                // 打开刚才定义的自定义输入弹窗
                this.customTargetDialog.open()
              }
            })
          } else {
            promptAction.showToast({ message: '请先点击头像登录' })
          }
        })


        Divider()

        this.mineItemBuilder($r('app.media.ic_mine_update'), '修改个人信息', () => {
          if (this.token) {
            router.pushUrl({ url: 'pages/UpdatePage' })
          } else {
            promptAction.showToast({ message: '请先点击头像登录' })
          }
        })

        Divider()

        // 【修改点】：去掉 if(this.token) 逻辑，直接执行跳转
        this.mineItemBuilder($r('app.media.ic_mine_card'), '生词本', () => {
          router.pushUrl({ url: 'pages/RawWordPage' })
        })

        Blank()

        if (this.token) {
          Button('退出登录')
            .width('100%')
            .fontSize(18)
            .backgroundColor(Color.Gray)
            .fontColor(Color.White)
            .onClick(() => {
              this.token = ''
              this.resetUserInfo()
              promptAction.showToast({ message: '已退出登录' })
            })
        }
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
      Image(icon).width(24).height(24)
      Text(title).fontSize(16).height(24).fontWeight(FontWeight.Medium)
      Blank()
      Image($r('app.media.ic_arrow_right')).width(24).height(24)
    }
    .width('100%')
    .height(40)
    .onClick(() => {
      callback?.()
    })
  }
}

@CustomDialog
struct TargetInputDialog {
  // 控制器，用于关闭弹窗
  controller: CustomDialogController = new CustomDialogController({ builder: '' })

  // ✅ 修复：直接使用函数类型表达式定义 confirm，不再依赖 interface
  confirm: (value: string) => void = (val: string) => {}

  // 内部状态，记录用户输入的数值
  @State inputText: string = ''

  build() {
    Column({ space: 15 }) {
      Text('自定义每日目标')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)

      TextInput({ placeholder: '请输入单词个数', text: this.inputText })
        .type(InputType.Number) // 强制弹出数字键盘
        .width('100%')
        .height(45)
        .backgroundColor('#F5F5F5')
        .onChange((value: string) => {
          this.inputText = value
        })

      Row({ space: 20 }) {
        Button('取消')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor('#666666')
          .onClick(() => {
            this.controller.close()
          })

        Button('确认')
          .layoutWeight(1)
          .backgroundColor(Color.Black)
          .fontColor(Color.White)
          // ✅ 严格类型检查：确保 inputText 长度判断逻辑正确
          .enabled(this.inputText.trim().length > 0)
          .onClick(() => {
            // ✅ 执行回调
            this.confirm(this.inputText)
            this.controller.close()
          })
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}