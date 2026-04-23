import {
  getLearnedHistory,
  getTodayTargetCount,
  getTodayLearnedCount,
  getTodayStudyDuration,
  setTodayTargetCount,
  setTodayLearnedCount,
  setTodayStudyDuration,
  DailyStudyRecordDto
} from '../http/Api';
import { StudyStatistics } from '../model/StudyStatistics';
import promptAction from '@ohos.promptAction';
import { StorageKeys } from '../store/GlobalState';

@Entry
@Component
export struct  StatisticsPage {
  @StorageLink(StorageKeys.STATISTICS_LIST) statisticsList: StudyStatistics[] = [];
  @StorageLink(StorageKeys.TOTAL_GOAL) totalGoal: number = 0;
  @StorageLink(StorageKeys.TODAY_LEARNED) todayLearned: number = 0;
  @StorageLink(StorageKeys.TODAY_TIME) todayTime: number = 0;
  @StorageLink(StorageKeys.IS_DATA_READY) isDataReady: boolean = false;


  // 风格常量
  private readonly CHART_BASE_HEIGHT: number = 240;
  private readonly PRIMARY_COLOR: string = '#48C9B0'; // 主色：青翠绿
  private readonly ACCENT_COLOR: string = '#EB984E';  // 强调：活力橙

  async aboutToAppear(): Promise<void> {
    if (!this.isDataReady) {
      await this.refreshAllData();
    }
  }

  /**
   * 综合刷新：保留完整网络逻辑 + 自动模拟数据
   */
  async refreshAllData(): Promise<void> {
    try {
      // 1. 获取后端数据（保留你指定的并行请求逻辑）
      // const results = await Promise.allSettled([
      //   getLearnedHistory(),
      //   getTodayTargetCount(),
      //   getTodayLearnedCount(),
      //   getTodayStudyDuration()
      // ]);

      // 开始加载时，确保门控关闭
      this.isDataReady = false;

      const history: DailyStudyRecordDto[] = await getLearnedHistory();
      // const target: number = await getTodayTargetCount();
      // const learned: number = await getTodayLearnedCount();
      // const duration: number = await getTodayStudyDuration();

      // 获取今天的日期字符串，格式为：YYYY-MM-DD
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const todayStr = `${year}-${month}-${day}`;

      // 在历史记录数组中，找到属于今天的记录
      const todayRecord = history.find(record => record.date === todayStr);

      // 2. 严谨赋值：不再依赖 history.length 是否大于 0
      // 这样即使没有历史数据，今日的概览数字（目标、已学）也能正常显示
      if(todayRecord)
      {
        this.totalGoal = Number(todayRecord.targetCount) || 0;
        this.todayLearned = Number(todayRecord.learnedCount) || 0;
        this.todayTime = Number(todayRecord.studyDuration) || 0;
      }
      else
      {
        this.totalGoal = 0;
        this.todayLearned = 0;
        this.todayTime = 0;
      }


      if (history && history.length > 0) {
        this.statisticsList = history.map((item: DailyStudyRecordDto): StudyStatistics => {
          return new StudyStatistics("", "", item.date, item.learnedCount, item.targetCount, item.studyDuration);
        });
      } else {
        this.statisticsList = []; // 明确清空列表，防止显示旧数据
      }
      this.isDataReady = true;
    } catch (error) {
      console.error('API Fetch Failed, loading mock data...');
      // 即便失败，也要关闭加载状态（或显示错误页）
      this.isDataReady = true;
      //this.injectMockData(); // 接口报错也注入，保证界面不白屏
    }
  }

  async syncTodayData(): Promise<void> {
    try {
      // await Promise.all([
      //   setTodayTargetCount(this.totalGoal),
      //   setTodayLearnedCount(this.todayLearned),
      //   setTodayStudyDuration(this.todayTime)
      // ]);
      await setTodayTargetCount(this.totalGoal)
      await setTodayLearnedCount(this.todayLearned)
      await setTodayStudyDuration(this.todayTime)
      promptAction.showToast({ message: '数据已同步至云端' });
      await this.refreshAllData();
    } catch (e) {
      promptAction.showToast({ message: '同步失败' });
    }
  }

  build() {
    Column() {
      // 头部
      Row() {
        Column() {
          Text('学习统计').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          Text('坚持是成功的唯一捷径').fontSize(13).fontColor('#999').margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Button('数据同步', { type: ButtonType.Capsule })
          .backgroundColor(this.PRIMARY_COLOR).height(32).fontSize(12)
          .onClick(() => this.syncTodayData())
      }.width('100%').padding({ left: 20, right: 20, top: 40, bottom: 20 })

      Scroll() {
        Column({ space: 20 }) {
          // // 美化后的图表卡片
          // this.ChartCardBuilder()
          // // 数据卡片网格
          // this.StatSummaryBuilder()
          if (this.isDataReady) {
            this.ChartCardBuilder()
            this.StatSummaryBuilder()
          } else {
            // 数据未准备好时，显示加载占位符或空白
            this.LoadingPlaceholderBuilder()
          }
        }.width('100%').padding(16)
      }.layoutWeight(1).edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%').backgroundColor('#F7F8FA')
  }

  @Builder ChartCardBuilder() {
    Column() {
      Row() {
        Text('近一周趋势').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
        Text('目标: ' + this.totalGoal).fontSize(12).fontColor('#666')
      }.width('100%').margin({ bottom: 25 })

      Row() {
        // Y轴
        Column() {
          Text(this.totalGoal.toString()).fontSize(10).fontColor('#CCC')
          Blank()
          Text('0').fontSize(10).fontColor('#CCC')
        }.height(this.CHART_BASE_HEIGHT).padding({ bottom: 22 })

        List({ space: 16 }) {
          ForEach(this.statisticsList, (item: StudyStatistics) => {
            ListItem() {
              Column() {
                Stack({ alignContent: Alignment.Bottom }) {
                  // 背景槽
                  Rect({ width: 14, height: this.CHART_BASE_HEIGHT }).fill('#F2F4F5').radius(7)
                  // 进度胶囊柱
                  Rect({
                    width: 14,
                    height: Math.min(this.CHART_BASE_HEIGHT, (item.learnedCount / (this.totalGoal || 1)) * this.CHART_BASE_HEIGHT)
                  })
                    .fill(item.learnedCount >= item.targetCount ? this.ACCENT_COLOR : this.PRIMARY_COLOR)
                    .radius(7)
                    .animation({ duration: 800, curve: Curve.EaseOut })
                }.height(this.CHART_BASE_HEIGHT)

                Text(item.statDate.substring(5)).fontSize(10).fontColor('#999').margin({ top: 8 })
              }
            }
          })
        }.listDirection(Axis.Horizontal).layoutWeight(1).margin({ left: 10 }).scrollBar(BarState.Off)
      }
    }
    .padding(20).backgroundColor('#FFF').borderRadius(24).shadow({ radius: 20, color: '#08000000' })
  }

  @Builder StatSummaryBuilder() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      // 传 Label 和颜色，Value 直接由 StatTile 自己读取
      this.StatTile('今日已背', this.PRIMARY_COLOR, () => this.todayLearned.toString())
      this.StatTile('学时时长', '#5DADE2', () => this.todayTime + 'm')
      this.StatTile('剩余任务', '#B2BABB', () => Math.max(0, this.totalGoal - this.todayLearned).toString())
      this.StatTile('目标达成', this.ACCENT_COLOR, () => Math.floor((this.todayLearned / (this.totalGoal || 1)) * 100) + '%')
    }
  }

  @Builder StatTile(label: string, color: string, getValue: () => string) {
    Column() {
      Row() {
        Circle({ width: 6, height: 6 }).fill(color).margin({ right: 6 })
        Text(label).fontSize(12).fontColor('#666')
      }
      // 调用函数获取最新值
      Text(getValue()).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 8 })
    }
    .width('48%').margin({ bottom: 15 }).padding(18)
    .backgroundColor('#FFF').borderRadius(20).alignItems(HorizontalAlign.Start)
  }

  @Builder
  LoadingPlaceholderBuilder() {
    Column() {
      LoadingProgress().width(40).height(40).color(this.PRIMARY_COLOR)
      Text('正在同步学习记录...').fontSize(14).fontColor('#999').margin({ top: 12 })
    }.width('100%').margin({ top: 100 })
  }
}