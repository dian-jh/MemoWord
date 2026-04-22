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

@Entry
@Component
struct StatisticsPage {
  @State statisticsList: StudyStatistics[] = [];
  @State totalGoal: number = 0;
  @State todayLearned: number = 0;
  @State todayTime: number = 0;

  // 风格常量
  private readonly CHART_BASE_HEIGHT: number = 240;
  private readonly PRIMARY_COLOR: string = '#48C9B0'; // 主色：青翠绿
  private readonly ACCENT_COLOR: string = '#EB984E';  // 强调：活力橙

  async aboutToAppear(): Promise<void> {
    await this.refreshAllData();
  }

  /**
   * 综合刷新：保留完整网络逻辑 + 自动模拟数据
   */
  async refreshAllData(): Promise<void> {
    try {
      // 1. 获取后端数据（保留你指定的并行请求逻辑）
      const results = await Promise.all([
        getLearnedHistory(),
        getTodayTargetCount(),
        getTodayLearnedCount(),
        getTodayStudyDuration()
      ]);

      // 2. 索引取值（遵循 ArkTS 规则）
      const history: DailyStudyRecordDto[] = results[0] as DailyStudyRecordDto[];
      const target: number = results[1] as number;
      const learned: number = results[2] as number;
      const duration: number = results[3] as number;

      // 3. 判断与渲染逻辑
      if (history && history.length > 0) {
        // --- 生产模式：使用真实数据 ---
        this.totalGoal = target;
        this.todayLearned = learned;
        this.todayTime = duration;
        this.statisticsList = history.map((item: DailyStudyRecordDto): StudyStatistics => {
          return new StudyStatistics("", "", item.date, item.learnedCount, item.targetCount, item.studyDuration);
        });
      } //else {
      //   // --- 预览/降级模式：如果接口没数据，注入精美的模拟数据 ---
      //   this.injectMockData();
      // }
    } catch (error) {
      console.error('API Fetch Failed, loading mock data...');
      //this.injectMockData(); // 接口报错也注入，保证界面不白屏
    }
  }

  // 模拟数据注入函数
  // private injectMockData(): void {
  //   this.totalGoal = 100;
  //   this.todayLearned = 65;
  //   this.todayTime = 45;
  //   const dates = ['2026-04-16', '2026-04-17', '2026-04-18', '2026-04-19', '2026-04-20', '2026-04-21', '2026-04-22'];
  //   const counts = [40, 85, 115, 30, 95, 75, 65];
  //   this.statisticsList = dates.map((d, i) => new StudyStatistics("", "", d, counts[i], 100, counts[i] * 0.6));
  // }

  async syncTodayData(): Promise<void> {
    try {
      await Promise.all([
        setTodayTargetCount(this.totalGoal),
        setTodayLearnedCount(this.todayLearned),
        setTodayStudyDuration(this.todayTime)
      ]);
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
          // 美化后的图表卡片
          this.ChartCardBuilder()
          // 数据卡片网格
          this.StatSummaryBuilder()
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
      this.StatTile('今日已背', this.todayLearned.toString(), this.PRIMARY_COLOR)
      this.StatTile('学时时长', this.todayTime + 'm', '#5DADE2')
      this.StatTile('剩余任务', Math.max(0, this.totalGoal - this.todayLearned).toString(), '#B2BABB')
      this.StatTile('目标达成', Math.floor((this.todayLearned / (this.totalGoal || 1)) * 100) + '%', this.ACCENT_COLOR)
    }
  }

  @Builder StatTile(label: string, value: string, color: string) {
    Column() {
      Row() {
        Circle({ width: 6, height: 6 }).fill(color).margin({ right: 6 })
        Text(label).fontSize(12).fontColor('#666')
      }
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A1A').margin({ top: 8 })
    }
    .width('48%').margin({ bottom: 15 }).padding(18)
    .backgroundColor('#FFF').borderRadius(20).alignItems(HorizontalAlign.Start)
  }
}