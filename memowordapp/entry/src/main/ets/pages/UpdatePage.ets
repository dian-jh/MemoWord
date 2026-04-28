import router from '@ohos.router';
import { AxiosResponse } from "@ohos/axios";
import { BusinessError } from '@ohos.base';
import {
  updateMe, info,
  UpdateUserReq, AuthUserInfo, UpdateUserRes, updatePassword,
  UpdatePasswordReq,
  UpdatePasswordRes
} from '../http/Api';
import { promptAction } from '@kit.ArkUI';
import picker from '@ohos.file.picker';




@Entry
@Component
struct UpdatePage {
  @State username: string = '';
  @State avatarUrl: string = '';
  @State account: string = '';
  @State createTime: string = '';
  @State isSubmitting: boolean = false;
  @State isLoading: boolean = true;

  // 修改密码弹窗
  @State showPwdDialog: boolean = false;
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State confirmPwd: string = '';

  aboutToAppear() {
    this.fetchLatestUserInfo();
  }

  // 获取用户信息
  private async fetchLatestUserInfo(): Promise<void> {
    try {
      this.isLoading = true;
      const res: AxiosResponse<AuthUserInfo> = await info();
      const data: AuthUserInfo = res.data;
      if (data) {
        this.username = data.username ?? '';
        this.avatarUrl = data.avatarUrl ?? '';
        this.account = data.account ?? '';
        this.createTime = data.createTime ?? '';
      }
    } catch (e) {
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  // 保存资料修改
  private async handleSubmit(): Promise<void> {
    if (!this.username.trim()) {
      promptAction.showToast({ message: '昵称不能为空' });
      return;
    }
    this.isSubmitting = true;
    try {
      const reqParam: UpdateUserReq = {
        username: this.username.trim(),
        avatarUrl: this.avatarUrl
      };
      await updateMe(reqParam);
      promptAction.showToast({ message: '修改成功' });
      router.back();
    } catch (e) {
      promptAction.showToast({ message: '保存失败' });
    } finally {
      this.isSubmitting = false;
    }
  }

  // 相册选择头像
  private async selectAvatar() {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const res = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (res.photoUris.length > 0) {
        this.avatarUrl = res.photoUris[0];
        promptAction.showToast({ message: '头像已选择' });
      }
    } catch (err) {
      promptAction.showToast({ message: '选择失败' });
    }
  }


  private async handleUpdatePwd() {
    // 1. 非空校验
    if (!this.oldPwd || !this.newPwd || !this.confirmPwd) {
      promptAction.showToast({ message: '请填写完整信息' });
      return;
    }

    // 2. 两次新密码一致校验
    if (this.newPwd !== this.confirmPwd) {
      promptAction.showToast({ message: '两次新密码不一致' });
      return;
    }

    try {
      // 3. 组装接口参数（对接 UpdatePasswordReq 类型）
      const params: UpdatePasswordReq = {
        oldPassword: this.oldPwd,
        newPassword: this.newPwd
      };

      // 4. 调用修改密码接口
      const res: AxiosResponse<UpdatePasswordRes> = await updatePassword(params);
      // 5. 根据后端返回 code 判断成功（按你后端实际规则调整）
      if (res.data.code === 1) {
        promptAction.showToast({ message: '密码修改成功' });

        // 6. 关闭弹窗 + 清空输入框
        this.showPwdDialog = false;
        this.oldPwd = '';
        this.newPwd = '';
        this.confirmPwd = '';
      } else {
        // 后端返回失败提示
        promptAction.showToast({ message: res.data.msg || '密码修改失败' });
      }
    } catch (error) {
      // 网络错误 / 接口异常
      console.error('修改密码接口异常：', error);
      promptAction.showToast({ message: '修改密码失败，请稍后重试' });
    }
  }












  build() {
    Stack() {
      // 全局柔和浅背景
      Column() {
        // 顶部纯白导航
        Row() {
          Image($r("app.media.ic_back"))
            .width(24)
            .height(24)
            .onClick(() => router.back())

          Text('个人资料')
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor('#222222')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('').width(24)
        }
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF')
        .padding({ left: 16, right: 16 })

        if (this.isLoading) {
          LoadingProgress().width(50).height(50).margin({ top: 120 })
        } else {
          Scroll() {
            Column({ space: 30 }) {

              // 头像区域 高级圆形+相机图标
              Stack({ alignContent: Alignment.BottomEnd }) {
                Image(this.avatarUrl || $r('app.media.img_avatar'))
                  .width(110)
                  .height(110)
                  .borderRadius(55)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#F3F4F6')
                  .shadow({ radius: 10, color: '#0000000F', offsetX: 0, offsetY: 4 })

                // 精致相机图标 深色圆角
                Row() {
                  Text('📷')
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                }
                .width(28)
                .height(28)
                .backgroundColor('#444444')
                .borderRadius(14)
                .justifyContent(FlexAlign.Center)
                .margin({ right: 6, bottom: 6 })
              }
              .onClick(() => this.selectAvatar())
              .margin({ top: 10 })

              Text('点击更换头像')
                .fontSize(12)
                .fontColor('#999999')

              // 信息卡片 纯白圆角 细腻阴影
              Column({ space: 0 }) {
                this.infoItem('账号', this.account, false)
                Divider().color('#F5F5F5').margin({ left: 20 })
                this.infoItem('昵称', this.username, true)
                Divider().color('#F5F5F5').margin({ left: 20 })
                this.infoItem('注册时间', this.formatTime(this.createTime), false)
                Divider().color('#F5F5F5').margin({ left: 20 })

                // 修改密码入口
                Row() {
                  Text('修改密码')
                    .fontSize(15)
                    .fontColor('#333333')
                  Blank()
                  Text('›')
                    .fontSize(20)
                    .fontColor('#BBBBBB')
                }
                .width('100%')
                .height(60)
                .padding({ left: 20, right: 20 })
                .onClick(() => this.showPwdDialog = true)
              }
              .width('94%')
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .shadow({ radius: 12, color: '#0000000A', offsetX: 0, offsetY: 3 })

              Blank().height(10)

              // 保存按钮 高级深灰 磨砂质感
              Button(this.isSubmitting ? '保存中...' : '保存修改')
                .width('94%')
                .height(50)
                .backgroundColor('#3A3A3A')
                .fontColor('#FFFFFF')
                .fontSize(16)
                .borderRadius(12)
                .enabled(!this.isSubmitting)
                .onClick(() => this.handleSubmit())

            }
            .alignItems(HorizontalAlign.Center)
            .padding({ bottom: 50 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9FAFB')

      // 密码弹窗 柔和圆角 简约风
      if (this.showPwdDialog) {
        Column() {
          Column({ space: 18 }) {
            Text('修改密码')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#222')

            TextInput({ placeholder: '请输入原密码', text: this.oldPwd })
              .type(InputType.Password)
              .width('100%')
              .height(48)
              .backgroundColor('#F6F7F9')
              .borderRadius(10)
              .padding({ left: 14 })
              .onChange(v => this.oldPwd = v)

            TextInput({ placeholder: '请输入新密码', text: this.newPwd })
              .type(InputType.Password)
              .width('100%')
              .height(48)
              .backgroundColor('#F6F7F9')
              .borderRadius(10)
              .padding({ left: 14 })
              .onChange(v => this.newPwd = v)

            TextInput({ placeholder: '请确认新密码', text: this.confirmPwd })
              .type(InputType.Password)
              .width('100%')
              .height(48)
              .backgroundColor('#F6F7F9')
              .borderRadius(10)
              .padding({ left: 14 })
              .onChange(v => this.confirmPwd = v)

            Row({ space: 15 }) {
              Button('取消')
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#EEEEEE')
                .fontColor('#666666')
                .borderRadius(10)
                .onClick(() => {
                  this.showPwdDialog = false;
                  this.oldPwd = '';
                  this.newPwd = '';
                  this.confirmPwd = '';
                })

              Button('确定')
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#333333')
                .fontColor('#FFFFFF')
                .borderRadius(10)
                .onClick(() => this.handleUpdatePwd())
            }
          }
          .width('88%')
          .padding(24)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .shadow({ radius: 20, color: '#00000015', offsetX: 0, offsetY: 5 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.25)')
        .justifyContent(FlexAlign.Center)
      }
    }
  }

  @Builder
  infoItem(label: string, value: string, isEdit: boolean) {
    Row() {
      Text(label)
        .width(75)
        .fontSize(15)
        .fontColor('#333333')

      if (isEdit) {
        TextInput({ text: this.username, placeholder: '请设置昵称' })
          .layoutWeight(1)
          .fontSize(15)
          .backgroundColor(Color.Transparent)
          .textAlign(TextAlign.End)
          .onChange(v => this.username = v)
      } else {
        Text(value || '暂无')
          .layoutWeight(1)
          .fontSize(14)
          .fontColor('#777777')
          .textAlign(TextAlign.End)
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 20, right: 20 })
  }

  // 时间格式化
  private formatTime(timeStr: string): string {
    if (!timeStr) return '暂无';
    return timeStr.includes('T') ? timeStr.replace('T', ' ').substring(0, 19) : timeStr;
  }
}