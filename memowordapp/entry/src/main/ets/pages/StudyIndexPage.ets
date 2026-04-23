import { promptAction, router } from '@kit.ArkUI';
// 【修改】：只引入 getLearnedHistory 和 setTodayTargetCount
import { getLearnedHistory, setTodayTargetCount,getTodayTargetCount } from '../http/Api';
import { StorageKeys } from '../store/GlobalState';
import { StudyStatistics } from '../model/StudyStatistics';


@Entry
@Component
export struct StudyIndexPage {
  @StorageLink(StorageKeys.STATISTICS_LIST) statisticsList: StudyStatistics[] = [];
  @StorageLink(StorageKeys.TOTAL_GOAL) todayTarget: number = 0;
  @StorageLink(StorageKeys.TODAY_LEARNED) learnedCount: number = 0;
  @StorageLink(StorageKeys.TODAY_TIME) studyDuration: number = 0;
  @StorageLink(StorageKeys.IS_DATA_READY) isDataReady: boolean = false;

  @State isLoading: boolean = true;

  @StorageLink('currentTabIndex') currentTabIndex: number = 0;

  @Watch('onRefreshSignal') @StorageLink('refreshFlag') refreshFlag: number = 0;

  // 目标设置弹窗
  targetDialogController: CustomDialogController = new CustomDialogController({
    builder: TargetSettingDialog({
      onSubmit: async (target: number): Promise<boolean> => {
        // 先更新本地全局状态，让 UI 瞬间变化
        this.todayTarget = target;
        // 同步后端
        await setTodayTargetCount(target);
        return true;
      }
    }),
    autoCancel: false,
    customStyle: true
  })

  // 【核心修改 1】：首次挂载到屏幕时触发（代替第一次的 onPageShow）
  aboutToAppear(): void {
    this.refreshData();
  }

  // 【核心修改 2】：当监听到 Index 页面传来 onPageShow 的信号时触发
  onRefreshSignal(): void {
    // 严谨判断：只有当前用户停留在“单词”这个 Tab（索引0）时，才发网络请求
    if (this.currentTabIndex === 0) {
      this.refreshData();
    }
  }

  // 每次页面显示时刷新数据（包括从练习页返回时）
  onPageShow(): void {
    this.refreshData();
  }

  private async refreshData(): Promise<void> {
    this.isLoading = true;
    try {
      // 1. 发起网络请求
      const historyList = await getLearnedHistory();

      const now = new Date();
      const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

      // 3. 更新全局统计列表（这是统计页图表的数据源）
      if (historyList && historyList.length > 0) {
        this.statisticsList = historyList.map((item): StudyStatistics => {
          return new StudyStatistics("", "", item.date, item.learnedCount, item.targetCount, item.studyDuration);
        });
      } else {
        this.statisticsList = [];
      }

      // 在历史记录数组中，找到属于今天的记录
      const todayRecord = historyList.find(record => record.date === todayStr);


      if (todayRecord) {
        // 如果找到了今天的记录，直接赋值（使用 Number 防御性转换，以防 JSON 解析偏差）
        this.todayTarget = Number(todayRecord.targetCount) || 0;
        this.learnedCount = Number(todayRecord.learnedCount) || 0;
        this.studyDuration = Number(todayRecord.studyDuration) || 0;
      } else {
        // 如果没找到，说明今天还没开始学，一切归零
        this.todayTarget = 0;
        this.learnedCount = 0;
        this.studyDuration = 0;
      }

      // 5. 标记全局数据已就绪，StatisticsPage 看到这个标志就不会再发请求了
      this.isDataReady = true;

      // 如果还没设定目标，主动弹窗
      if (this.todayTarget <= 0) {
        this.targetDialogController.open();
      }
    } catch (e) {
      console.error('StudyIndex_Debug', '刷新看板数据失败', JSON.stringify(e));
      // 失败也要结束 loading
      this.isDataReady = true;
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      // 头部标题
      Text('学习概览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 40, bottom: 30 })

      // 中心进度圆环
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

      // 学习时长卡片
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

      // 开始按钮
      Button('开始背单词吧！')
        .width('80%')
        .height(60)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#1FBE93')
        .borderRadius(30)
        .margin({ bottom: 50 })
        .onClick(() => {
          // 如果目标设定好了，跳转去背单词；如果还没设，拦住他去设目标
          if (this.todayTarget > 0) {
            router.pushUrl({ url: 'pages/PracticePage' })
          } else {
            this.targetDialogController.open()
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}

// ======================== 弹窗组件 ========================

@CustomDialog
struct TargetSettingDialog {
  onSubmit: (target: number) => Promise<boolean> = async () => false
  @State inputValue: string = ''
  @State isSubmitting: boolean = false
  controller: CustomDialogController = new CustomDialogController({ builder: TargetSettingDialog() })

  build() {
    Column({ space: 18 }) {
      Text('设定今日学习目标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      TextInput({ text: this.inputValue, placeholder: '请输入每日学习单词数量' })
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
          this.isSubmitting = true
          if (await this.onSubmit(count)) this.controller.close()
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