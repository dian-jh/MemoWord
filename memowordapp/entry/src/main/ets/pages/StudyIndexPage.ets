import { promptAction, router } from '@kit.ArkUI';
import { getLearnedHistory, setTodayTargetCount } from '../http/Api';

@Entry
@Component
export struct StudyIndexPage {
  @State todayTarget: number = 0;
  @State learnedCount: number = 0;
  @State studyDuration: number = 0; // 分钟
  @State isLoading: boolean = true;

  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  @Watch('onRefreshSignal') @StorageLink('refreshFlag') refreshFlag: number = 0;

  targetDialogController: CustomDialogController = new CustomDialogController({
    builder: TargetSettingDialog({
      // 把当前已学数量传给弹窗，方便做提示
      currentLearned: this.learnedCount,
      onSubmit: async (target: number): Promise<boolean> => {
        await setTodayTargetCount(target);
        this.refreshData();
        return true;
      }
    }),
    autoCancel: false,
    customStyle: true
  })

  aboutToAppear(): void {
    this.refreshData();
  }

  onRefreshSignal(): void {
    if (this.currentTabIndex === 0) {
      this.refreshData();
    }
  }

  private async refreshData(): Promise<void> {
    this.isLoading = true;
    try {
      const historyList = await getLearnedHistory();

      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const todayStr = `${year}-${month}-${day}`;

      const todayRecord = historyList.find(record => record.date === todayStr);

      if (todayRecord) {
        this.todayTarget = Number(todayRecord.targetCount) || 0;
        this.learnedCount = Number(todayRecord.learnedCount) || 0;
        this.studyDuration = Number(todayRecord.studyDuration) || 0;
      } else {
        this.todayTarget = 0;
        this.learnedCount = 0;
        this.studyDuration = 0;
      }

      if (this.todayTarget <= 0) {
        this.targetDialogController.open();
      }
    } catch (e) {
      console.error('StudyIndex_Debug', '刷新看板数据失败', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  // 动态获取按钮文本
  private getButtonText(): string {
    if (this.todayTarget <= 0) return '设定学习目标';
    if (this.learnedCount >= this.todayTarget) return '再来一组吧！';
    return '开始背单词吧！';
  }

  build() {
    Column() {
      Text('学习概览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 40, bottom: 30 })

      Stack() {
        DataPanel({
          values: [this.learnedCount],
          max: this.todayTarget > 0 ? this.todayTarget : 100,
          type: DataPanelType.Circle
        })
          .width(220)
          .height(220)

        Column() {
          Text(`${this.learnedCount}`)
            .fontSize(50)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1FBE93')
          Text(`目标 ${this.todayTarget}`)
            .fontSize(16)
            .fontColor('#888')
        }
      }
      .margin({ bottom: 40 })

      Row() {
        Column({ space: 8 }) {
          Text('今日学习时长')
            .fontSize(14)
            .fontColor('#888')
          Text(`${this.studyDuration} 分钟`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#1E1E21')
      .borderRadius(20)

      Blank()

      Button(this.getButtonText())
        .width('80%')
        .height(60)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#1FBE93')
        .borderRadius(30)
        .margin({ bottom: 50 })
        .onClick(() => {
          // 【核心逻辑分发】
          if (this.todayTarget <= 0 || this.learnedCount >= this.todayTarget) {
            // 如果没设目标，或者目标已完成（想再来一组），都打开弹窗修改目标
            this.targetDialogController.open()
          } else {
            // 目标未完成，正常去背单词
            router.pushUrl({ url: 'pages/PracticePage' })
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}

// ======================== 弹窗组件 ========================
// 必须定义在同一个文件里，并被上面的 Controller 引用

@CustomDialog
struct TargetSettingDialog {
  currentLearned: number = 0; // 接收外部传来的已学数量
  onSubmit: (target: number) => Promise<boolean> = async () => false;

  @State inputValue: string = '';
  @State isSubmitting: boolean = false;
  controller: CustomDialogController = new CustomDialogController({ builder: TargetSettingDialog() })

  build() {
    Column({ space: 18 }) {
      Text('设定今日学习目标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      // 友好提示，防止用户在“再来一组”时输入比已学还小的数字
      if (this.currentLearned > 0) {
        Text(`您今日已学 ${this.currentLearned} 词，新目标需大于此数值`)
          .fontSize(12)
          .fontColor('#1FBE93')
      }

      TextInput({ text: this.inputValue, placeholder: '请输入总目标单词数量' })
        .type(InputType.Number)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#2C2C30')
        .borderRadius(14)
        .height(50)
        .padding({ left: 16, right: 16 })
        .onChange((v: string) => this.inputValue = v)

      Button(this.isSubmitting ? '提交中...' : '确认')
        .width('100%')
        .height(50)
        .backgroundColor('#1FBE93')
        .fontColor('#FFFFFF')
        .fontWeight(700)
        .fontSize(16)
        .borderRadius(14)
        .shadow({ radius: 8, color: '#1FBE9333', offsetX: 0, offsetY: 4 })
        .onClick(async () => {
          const count = parseInt(this.inputValue, 10)

          if (isNaN(count) || count <= 0) {
            promptAction.showToast({ message: '请输入大于0的数字' })
            return
          }

          if (count <= this.currentLearned && this.currentLearned > 0) {
            promptAction.showToast({ message: `新目标必须大于已学的 ${this.currentLearned} 词` })
            return
          }

          this.isSubmitting = true
          if (await this.onSubmit(count)) {
            this.inputValue = ''; // 清空输入框
            this.controller.close()
          }
          this.isSubmitting = false
        })
    }
    .width('85%')
    .padding(20)
    .backgroundColor('#252528')
    .borderRadius(20)
    .shadow({ radius: 20, color: '#0005', offsetX: 0, offsetY: 6 })
  }
}