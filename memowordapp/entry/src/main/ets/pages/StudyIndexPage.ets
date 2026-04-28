import { promptAction, router } from '@kit.ArkUI';
import { getLearnedHistory, setTodayTargetCount } from '../http/Api';
import { StorageKeys } from '../store/GlobalState';
import { StudyStatistics } from '../model/StudyStatistics';

@Entry
@Component
struct StudyIndexPage {
  @StorageLink(StorageKeys.STATISTICS_LIST) statisticsList: StudyStatistics[] = [];
  @StorageLink(StorageKeys.TOTAL_GOAL) todayTarget: number = 0;
  @StorageLink(StorageKeys.TODAY_LEARNED) learnedCount: number = 0;
  @StorageLink(StorageKeys.TODAY_TIME) studyDuration: number = 0;
  @StorageLink(StorageKeys.IS_DATA_READY) isDataReady: boolean = false;

  @State isLoading: boolean = true;
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  @Watch('onRefreshSignal') @StorageLink('refreshFlag') refreshFlag: number = 0;

  // 输入目标相关状态
  @State inputTarget: string = '';
  @State showSetTargetDialog: boolean = false;

  // 防重复请求锁
  private isRequesting: boolean = false;

  aboutToAppear(): void {
    this.refreshData();
  }

  onRefreshSignal(): void {
    if (this.currentTabIndex === 0) {
      this.refreshData();
    }
  }

  onPageShow(): void {
    if (this.currentTabIndex === 0) {
      this.refreshData();
    }
  }

  /**
   * 核心数据请求，加防重复请求锁
   */
  private async refreshData(): Promise<void> {
    if (this.isRequesting) return;
    this.isRequesting = true;
    this.isLoading = true;
    try {
      const historyList = await getLearnedHistory();
      const now = new Date();
      const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

      if (historyList && historyList.length > 0) {
        this.statisticsList = historyList.map((item): StudyStatistics => {
          return new StudyStatistics("", "", item.date, item.learnedCount, item.targetCount, item.studyDuration);
        });
      } else {
        this.statisticsList = [];
      }

      const todayRecord = historyList.find(record => record.date === todayStr);
      if (todayRecord) {
        // ✅ 强制转换并赋值，确保响应式监听生效
        const learned = Number(todayRecord.learnedCount) || 0;

        // 更新全局状态，这会自动同步到 UI 上的 learnedCount
        AppStorage.setOrCreate(StorageKeys.TODAY_LEARNED, learned);

        this.todayTarget = Number(todayRecord.targetCount) || 0;
        this.studyDuration = Number(todayRecord.studyDuration) || 0;
      }else {
        this.todayTarget = AppStorage.get<number>(StorageKeys.TOTAL_GOAL) || 0;
        this.learnedCount = 0;
        this.studyDuration = 0;
      }

      this.isDataReady = true;
    } catch (e) {
      console.error('StudyIndex_Debug', '刷新看板数据失败', JSON.stringify(e));
      this.isDataReady = true;
    } finally {
      this.isLoading = false;
      this.isRequesting = false;
    }
  }

  /**
   * 保存设置今日目标
   */
  private async saveTodayTarget() {
    const target = parseInt(this.inputTarget.trim())
    if (isNaN(target) || target <= 0) {
      promptAction.showToast({ message: '请输入有效的数字' })
      return
    }

    try {
      await setTodayTargetCount(target)
      this.todayTarget = target
      this.showSetTargetDialog = false
      promptAction.showToast({ message: '目标设置成功！' })
    } catch (e) {
      promptAction.showToast({ message: '设置失败，请重试' })
    }
  }

  /**
   * 计算剩余单词
   */
  private getRemainCount(): number {
    return Math.max(this.todayTarget - this.learnedCount, 0);
  }

  /**
   * 计算完成进度百分比
   */
  private getProgressPercent(): number {
    if (this.todayTarget <= 0) return 0;
    return Math.min(Math.round((this.learnedCount / this.todayTarget) * 100), 100);
  }

  /**
   * 毫秒智能格式化为 小时/分钟
   */
  private formatStudyTime(): string {
    const totalMin = Math.floor(this.studyDuration / 60000);
    if (totalMin === 0) return "0 分钟";
    if (totalMin >= 60) {
      const hour = Math.floor(totalMin / 60);
      const min = totalMin % 60;
      return `${hour} 小时 ${min} 分钟`;
    } else {
      return `${totalMin} 分钟`;
    }
  }

  build() {
    // 修复：只有一个根节点 Column
    Column() {
      // 顶部标题 + 右上角搜索按钮
      Stack() {
        Text('学习概览')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .width('100%')
          .textAlign(TextAlign.Center)

        // 右上角搜索按钮
        Row() {
          Image($r('app.media.ic_search'))
            .width(28)
            .height(28)
            .onClick(() => {
              router.pushUrl({ url: 'pages/SearchPage' });
            })
        }
        .position({ right: 20, top: 0 })
      }
      .width('100%')
      .margin({ top: 55, bottom: 25 })

      // 中心进度圆环 + 完成率
      Stack({ alignContent: Alignment.Center }) {
        DataPanel({
          values: [this.learnedCount],
          max: this.todayTarget > 0 ? this.todayTarget : 100,
          type: DataPanelType.Circle
        })
          .width(240)
          .height(240)

        Column({ space: 8 }) {
          Text(`${this.learnedCount}`)
            .fontSize(54)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1FBE93')

          Text(`${this.getProgressPercent()}% 已完成`)
            .fontSize(16)
            .fontColor('#666666')

          if (this.todayTarget > 0) {
            Text(`剩余 ${this.getRemainCount()} 个`)
              .fontSize(14)
              .fontColor('#999999')
          }
        }
      }
      .margin({ bottom: 35 })

      // 双卡片布局：学习时长 + 今日目标 —— 平均分配宽度
      Row({ space: 16 }) {
        // 时长卡片
        Column({ space: 8 }) {
          Text('今日学习时长')
            .fontSize(15)
            .fontColor('#666666')
          Text(`${this.formatStudyTime()}`)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
        }
        .alignItems(HorizontalAlign.Start)
        .padding(22)
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 3 })

        // 目标卡片
        Column({ space: 8 }) {
          Text('今日学习目标')
            .fontSize(15)
            .fontColor('#666666')
          Text(`${this.todayTarget} 个单词`)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
        }
        .alignItems(HorizontalAlign.Start)
        .padding(22)
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .shadow({ radius: 8, color: '#0000000F', offsetX: 0, offsetY: 3 })
      }
      .width('92%')
      .margin({ bottom: 30 })

      // 自适应空白撑开布局
      Column() {}.layoutWeight(1)

      // 开始背单词主按钮
      Button(this.todayTarget > 0 ? '开始背单词' : '设置每日学习目标')
        .width('84%')
        .height(66)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#1FBE93')
        .borderRadius(33)
        .margin({ bottom: 60 })
        .shadow({ radius: 12, color: '#1FBE9330', offsetX: 0, offsetY: 8 })
        .onClick(() => {
          if (this.todayTarget > 0) {
            router.pushUrl({ url: 'pages/PracticePage' })
          } else {
            // 直接弹出设置框
            this.inputTarget = ''
            this.showSetTargetDialog = true
          }
        })

      // ====================== 目标设置弹窗（包进根Column里） ======================
      if (this.showSetTargetDialog) {
        Column() {
          Text('设置今日学习目标')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20, top: 24 })

          TextInput({ text: this.inputTarget, placeholder: '请输入数字（如 50）' })
            .width('80%')
            .height(50)
            .textAlign(TextAlign.Center)
            .fontSize(18)
            .type(InputType.Number)
            .onChange(v => this.inputTarget = v)
            .margin({ bottom: 24 })

          Row({ space: 20 }) {
            Button('取消')
              .width(120)
              .height(50)
              .backgroundColor('#eee')
              .fontColor('#333')
              .onClick(() => {
                this.showSetTargetDialog = false
              })

            Button('确定')
              .width(120)
              .height(50)
              .backgroundColor('#1FBE93')
              .onClick(() => {
                this.saveTodayTarget()
              })
          }
        }
        .width('90%')
        .backgroundColor('#fff')
        .borderRadius(20)
        .alignItems(HorizontalAlign.Center)
        .position({ left: '5%', top: '25%' })
        .shadow({ radius: 10, color: '#00000010' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F7F2')
  }
}

export { StudyIndexPage };