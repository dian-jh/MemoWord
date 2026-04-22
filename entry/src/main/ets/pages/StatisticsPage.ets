import {
  getLearnedHistory,
  getTodayTargetCount,
  getTodayLearnedCount,
  getTodayStudyDuration,
  setTodayTargetCount,
  setTodayLearnedCount,
  setTodayStudyDuration,
  DailyStudyRecordDto,
  HttpResult
} from '../http/Api'; // 路径请根据实际情况修改
import { StudyStatistics } from '../model/StudyStatistics';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct StatisticsPage {
  // 1. 状态变量
  @State statisticsList: StudyStatistics[] = [];
  @State totalGoal: number = 0;
  @State todayLearned: number = 0;
  @State todayTime: number = 0;

  private readonly CHART_BASE_HEIGHT: number = 240;

  // 2. 页面进入时加载数据
  async aboutToAppear(): Promise<void> {
    await this.refreshAllData();
  }

  // 综合刷新方法：获取历史记录 + 今日实时数据
  async refreshAllData(): Promise<void> {
    try {
      // 1. 先获取整个结果数组，不要在这里解构
      const results = await Promise.all([
        getLearnedHistory(),
        getTodayTargetCount(),
        getTodayLearnedCount(),
        getTodayStudyDuration()
      ]);

      // 2. 通过索引逐个取值
      const history: DailyStudyRecordDto[] = results[0] as DailyStudyRecordDto[];
      const target: number = results[1] as number;
      const learned: number = results[2] as number;
      const duration: number = results[3] as number;

      // 3. 更新状态变量
      this.totalGoal = target;
      this.todayLearned = learned;
      this.todayTime = duration;

      this.statisticsList = history.map((item: DailyStudyRecordDto): StudyStatistics => {
        return new StudyStatistics(
          "",
          "",
          item.date,
          item.learnedCount,
          item.targetCount,
          item.studyDuration // 字段已对齐后端
        );
      });
    } catch (error) {
      console.error('刷新统计数据失败');
    }
  }

  // 3. 同步数据：分别调用三个设置接口
  async syncTodayData(): Promise<void> {
    try {
      // 分别调用原子化接口进行设置
      await Promise.all([
        setTodayTargetCount(this.totalGoal),
        setTodayLearnedCount(this.todayLearned),
        setTodayStudyDuration(this.todayTime)
      ]);

      promptAction.showToast({ message: '同步成功' });
      await this.refreshAllData(); // 同步后刷新界面
    } catch (error) {
      promptAction.showToast({ message: '同步部分失败，请重试' });
    }
  }

  build() {
    Column() {
      // 头部标题与同步按钮
      Row() {
        Text('学习统计')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('数据同步')
          .fontSize(12)
          .backgroundColor('#48C9B0')
          .onClick(() => {
            this.syncTodayData();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 40, bottom: 10 })

      // 柱状图区域
      Column() {
        Row() {
          // Y轴刻度（基于当前目标动态变化）
          Column() {
            Text((this.totalGoal > 0 ? this.totalGoal * 2 : 200).toString()).fontSize(10).fontColor('#999')
            Blank()
            Text((this.totalGoal > 0 ? this.totalGoal : 100).toString()).fontSize(10).fontColor('#999')
            Blank()
            Text('0').fontSize(10).fontColor('#999')
          }
          .height(this.CHART_BASE_HEIGHT)
          .padding({ bottom: 25, top: 5 })
          .margin({ right: 10 })

          // 历史记录列表
          List({ space: 20 }) {
            ForEach(this.statisticsList, (item: StudyStatistics) => {
              ListItem() {
                Column() {
                  Stack({ alignContent: Alignment.Bottom }) {
                    Rect({ width: 22, height: this.CHART_BASE_HEIGHT })
                      .fill('#F0F0F0')
                      .radius(4)

                    Rect({
                      width: 22,
                      // 计算高度比例
                      height: this.totalGoal > 0
                        ? (item.learnedCount / (this.totalGoal * 2)) * this.CHART_BASE_HEIGHT
                        : 0
                    })
                      .fill('#48C9B0')
                      .radius(4)
                      .animation({ duration: 600, curve: Curve.FastOutSlowIn })
                  }
                  .height(this.CHART_BASE_HEIGHT)

                  Text(item.statDate.split('-').slice(1).join('/')) // 简化日期显示如 04/22
                    .fontSize(10)
                    .fontColor('#666')
                    .margin({ top: 8 })
                }
              }
            }, (item: StudyStatistics): string => item.statDate)
          }
          .listDirection(Axis.Horizontal)
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('94%')
      .padding(15)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .margin({ top: 20 })
      .shadow({ radius: 10, color: '#15000000' })

      // 底部详情卡片
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        this.StatCard('今日已背', this.todayLearned.toString(), '#48C9B0')
        this.StatCard('今日时长', this.todayTime + ' min', '#5DADE2')
        this.StatCard('剩余任务', Math.max(0, this.totalGoal - this.todayLearned).toString(), '#B2BABB')
        this.StatCard('每日目标', this.totalGoal.toString(), '#EB984E')
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  @Builder StatCard(label: string, value: string, color: string) {
    Row() {
      Circle({ width: 8, height: 8 }).fill(color).margin({ right: 10 })
      Column() {
        Text(label).fontSize(14).fontColor('#666')
        Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333').margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start)
    }
    .width('48%')
    .margin({ bottom: 20 })
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#10000000' })
  }
}