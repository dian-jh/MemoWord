
// import router from '@ohos.router';
// import promptAction from '@ohos.promptAction';
// import { info, AuthUserInfo } from '../http/Api'; // 导入获取用户信息的接口和类型定义
// import { AxiosResponse } from "@ohos/axios"; // 导入 Axios 响应类型，用于规范异步返回的数据结构
// import { Driver } from '@kit.TestKit';
//
// @Component
// export struct MinePage {
//   // ==========================================
//   // 模块一：全局状态与组件私有变量
//   // ==========================================
//   // @StorageLink：双向同步 AppStorage 中的 token。当登录成功设置 token 后，这里会自动更新
//   // @Watch：监听 token 的变化，一旦 token 改变（如登录或退出），自动执行 onTokenChange 方法
//   @StorageLink('token') @Watch('onTokenChange') token: string = ''
//
//   // @State：组件内部状态。用于存储从后端获取的完整用户信息
//   // 如果你要添加修改功能，你会修改这个变量的值，或者将它的属性（如 username）传给新组件
//   @State userInfo: AuthUserInfo = {
//     id: '',          // 用户唯一标识（UUID）
//     username: '',    // 用户昵称
//     account: '',     // 账号/手机号
//     avatarUrl: '',   // 头像地址
//     createTime:''    // 账号创建时间
//   };
//
//   // ==========================================
//   // 模块二：数据生命周期与监听逻辑
//   // ==========================================
//   // 监听器：当 token 发生变化时（例如在 LoginPage 登录成功后返回此页）触发
//   async onTokenChange() {
//     if (this.token) { // 如果 token 不为空，说明已登录
//       try {
//         // 调用 info() 接口，手动指定响应数据为 AuthUserInfo 类型
//         let response: AxiosResponse<AuthUserInfo> = await info()
//         // 将后端返回的最新数据（response.data）赋值给 userInfo 状态，触发 UI 刷新
//         this.userInfo = response.data;
//
//         //TODO
//         console.info("用户信息为：")
//         console.info("this.userInfo:" + JSON.stringify(this.userInfo))
//         console.info("response.data:" + JSON.stringify(response.data))
//
//       } catch (e) {
//         console.error("获取用户信息失败") // 网络异常或 token 失效时的错误处理
//       }
//     } else {
//       this.resetUserInfo() // 如果 token 变为空（退出登录），则清空本地用户信息
//     }
//   }
//
//   // 生命周期：组件初始化加载时执行。防止用户刷新页面后数据丢失
//   async aboutToAppear() {
//     if (this.token) { // 检查当前是否有登录凭证
//       try {
//         let response: AxiosResponse<AuthUserInfo> = await info() // 请求用户信息
//         this.userInfo = response.data; // 更新状态以展示数据
//       } catch (e) {
//         console.error("初始化用户信息失败") // 捕获初始化时的请求异常
//       }
//     }
//   }
//
//   // async onPageShow() {
//   //   if (this.token) {
//   //     try {
//   //       console.info("MinePage 回到前台，重新拉取最新数据...");
//   //       let response: AxiosResponse<AuthUserInfo> = await info(); // 再次调 GET /users/me
//   //       this.userInfo = response.data;
//   //     } catch (e) {
//   //       console.error("刷新用户信息失败")
//   //     }
//   //   }
//
//   // 工具函数：重置用户信息。当点击退出登录时，必须调用此方法防止信息残留
//   resetUserInfo() {
//     this.userInfo = { id: '', username: '', account: '', avatarUrl: '' ,createTime:''}
//   }
//
//   // ==========================================
//   // 模块三：UI 视图构建（主要布局）
//   // ==========================================
//   build() {
//     Stack() { // 使用层叠布局，让背景图和内容重叠
//       // --- 顶部个人资料展示区 ---
//       Column() {
//         // 头像展示：根据 token 状态和是否有 avatarUrl 决定显示网络图还是本地默认占位图
//         Image(this.token && this.userInfo.avatarUrl ? this.userInfo.avatarUrl : $r('app.media.img_avatar'))
//           .width(150)        // 设置头像宽度
//           .height(150)       // 设置头像高度
//           .borderRadius(70)  // 圆角 50 使其呈现圆形
//           .margin({ top: 50 }) // 顶部间距
//           .onClick(() => {
//             if (!this.token) { // 如果未登录，点击头像跳转到登录页
//               router.pushUrl({ url: 'pages/LoginPage' })
//             }
//           })
//
//         // 用户名展示：登录显示真实昵称，未登录显示提示语
//         Text(this.token? this.userInfo.username : '暂未登录')
//           .fontSize(20)              // 文字大小
//           .fontWeight(FontWeight.Bold) // 加粗
//           .fontColor(Color.Black)      // 颜色
//           .margin({ top: 20 })         // 与头像的间距
//
//         if (!this.token) { // 仅在未登录状态下显示的补充提示文字
//           Text('请点击头像登录')
//             .fontSize(20)
//             .fontWeight(FontWeight.Medium)
//             .fontColor(Color.Black)
//             .margin({ top: 4 })
//         }
//       }
//       .width('100%') // 容器宽度撑满
//       .height('50%') // 占据屏幕上半部分
//       // 背景图：取用户头像并应用模糊效果，增加视觉高级感
//       .backgroundImage(this.token && this.userInfo.avatarUrl ? this.userInfo.avatarUrl : $r('app.media.img_avatar'))
//       .backgroundImageSize({ height: '100%', width: '100%' }) // 背景图覆盖整个容器
//       .backgroundBlurStyle(BlurStyle.Regular) // 应用系统常规模糊样式
//
//       // --- 底部功能菜单列表区 ---
//       Column({ space: 10 }) { // 纵向排列，子组件间距为 10
//         // 打卡记录入口
//         this.mineItemBuilder($r('app.media.ic_mine_card'), '打卡记录', () => {
//           if (this.token) {
//             router.pushUrl({ url: 'pages/PostHistoryPage' }) // 已登录则跳转记录页
//           } else {
//             promptAction.showToast({ message: '请先点击头像登录' }) // 未登录提示
//           }
//         })
//
//         Divider() // 分割线
//
//         // MinePage.ets 中修改个人信息的跳转逻辑
//         this.mineItemBuilder($r('app.media.ic_mine_update'), '修改个人信息', () => {
//           if (this.token) {
//             console.info("准备进入修改页，让修改页自己去拉取数据");
//             router.pushUrl({
//               url: 'pages/UpdatePage' // ✅ 干干净净，不再传参数
//             })
//           } else {
//             promptAction.showToast({ message: '请先点击头像登录' })
//           }
//         })
//
//         Divider()
//         // 其他功能按钮（示例）
//         this.mineItemBuilder($r('app.media.ic_mine_update'), '检查更新', () => {
//           promptAction.showToast({ message: '已是最新' })
//         })
//
//         Divider()
//
//         this.mineItemBuilder($r('app.media.ic_mine_about'), '关于', () => {
//           promptAction.showToast({ message: '没有关于' })
//         })
//
//         Blank() // 自动填充剩余垂直空间，将“退出登录”按钮挤到底部
//
//         // --- 模块四：账户操作区 ---
//         if (this.token) { // 只有在登录状态下才显示退出按钮
//           Button('退出登录')
//             .width('100%')             // 按钮宽度撑满
//             .fontSize(18)              // 字体大小
//             .backgroundColor(Color.Gray) // 灰色背景表示次要或警告操作
//             .fontColor(Color.White)      // 白色文字
//             .onClick(() => {
//               this.token = ''          // 清空 token，会自动触发 @Watch 监听同步到全局
//               this.resetUserInfo()      // 手动清空当前页面的用户信息显示
//               promptAction.showToast({ message: '已退出登录' }) // 提示语
//             })
//         }
//       }
//       .width('100%')      // 菜单宽度
//       .height('60%')      // 菜单高度（从底部往上占 60%）
//       .offset({ y: '40%' }) // 向下偏移，使菜单顶部和个人信息区衔接
//       .borderRadius({ topLeft: 50, topRight: 50 }) // 顶部大圆角，营造卡片感
//       .backgroundColor(Color.White) // 菜单背景为纯白
//       .padding(30)         // 内部留白
//
//     }.width('100%')
//     .height('100%')
//     .alignContent(Alignment.Top) // 整体内容向上对齐
//   }
//
//   // ==========================================
//   // 模块五：UI 构建器（复用组件）
//   // ==========================================
//   // @Builder：用于创建可复用的 UI 片段。
//   // 参数说明：icon（图标资源）、title（标题文字）、callback（点击后的逻辑函数）
//   @Builder
//   mineItemBuilder(icon: Resource, title: string, callback?: () => void) {
//     Row({ space: 10 }) { // 横向排列图标和文字
//       Image(icon).width(24).height(24) // 渲染左侧小图标
//       Text(title).fontSize(16).height(24).fontWeight(FontWeight.Medium) // 渲染功能标题
//       Blank() // 中间占位，将箭头推向最右侧
//       Image($r('app.media.ic_arrow_right')).width(24).height(24) // 渲染右侧箭头图标
//     }
//     .width('100%') // 每一行占满宽度
//     .height(40)    // 固定高度
//     .onClick(() => {
//       callback?.() // 如果传入了逻辑，则在点击时执行（比如跳转页面或弹窗）
//     })
//   }
// }





















import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthUserInfo, info, updateTargetWords } from '../http/Api';
import { AxiosResponse } from "@ohos/axios";

@Component
export struct MinePage {
  @StorageLink('token') @Watch('onTokenChange') token: string = ''
  @StorageLink('temp_username') tempName :string =''
  // ✅ 新增：监听全局刷新信号。一旦这个值改变，就会触发刷新
  @StorageProp('needRefreshMine') @Watch('onSignalChange') refreshSignal: number = 0

  @State userInfo: AuthUserInfo = {
    id: '',
    username: '',
    account: '',
    avatarUrl: '',
    createTime: '',
    targetWords: 0
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
    this.userInfo = { id: '', username: '', account: '', avatarUrl: '' ,createTime:'',targetWords:20}
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



  private saveTarget(num: string) {
    let targetNum: number = parseInt(num);

    updateTargetWords(targetNum).then(() => {

      this.userInfo.targetWords = targetNum;
      promptAction.showToast({
        message: '修改成功，当前每日目标单词数为：' + targetNum
      });
      this.userInfo.targetWords = targetNum;
    }).catch(() => {
      promptAction.showToast({ message: '修改失败' });
    });
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
        this.mineItemBuilder($r('app.media.ic_mine_card'), '打卡记录', () => {
          if (this.token) {
            router.pushUrl({ url: 'pages/PostHistoryPage' })
          } else {
            promptAction.showToast({ message: '请先点击头像登录' })
          }
        })

        Divider()

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
        this.mineItemBuilder($r('app.media.ic_mine_update'), '检查更新', () => {
          promptAction.showToast({ message: '已是最新' })
        })

        Divider()
        this.mineItemBuilder($r('app.media.ic_mine_about'), '关于', () => {
          promptAction.showToast({ message: '没有关于' })
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