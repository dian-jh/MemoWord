// 导入必须包含这几个接口
import { getStatisticsHistory, DailyStatistics, ApiResponse, updateDailyStatistics } from '../http/Api';
import { StudyStatistics } from '../model/StudyStatistics';
import promptAction from '@ohos.promptAction';
import { AxiosResponse } from '@ohos/axios'; // 确保导入了这个类型

@Entry
@Component
struct StatisticsPage {
  @State statisticsList: StudyStatistics[] = [];
  @State totalGoal: number = 100;
  @State todayLearned: number = 0;
  @State todayTime: number = 0;

  private readonly CHART_BASE_HEIGHT: number = 240;

  async aboutToAppear(): Promise<void> {
    await this.fetchStatistics();
  }

  // --- 获取数据：彻底消灭 any ---
  async fetchStatistics(): Promise<void> {
    try {
      // 核心修改 1：给 res 增加显式的类型标注 AxiosResponse<ApiResponse<DailyStatistics[]>>
      const res: AxiosResponse<ApiResponse<DailyStatistics[]>> = await getStatisticsHistory();

      // 核心修改 2：直接使用 res.data，因为它已经由于上面的标注变成了强类型
      const response: ApiResponse<DailyStatistics[]> = res.data;

      if (response && response.code === 200) {
        const serverData: DailyStatistics[] = response.data;

        this.statisticsList = serverData.map((item: DailyStatistics): StudyStatistics => {
          return new StudyStatistics(
            item.id ?? '',
            item.userId ?? '',
            item.statDate ?? '',
            item.learnedCount,
            item.targetCount,
            item.timeUsed
          );
        });

        if (this.statisticsList.length > 0) {
          const latest: StudyStatistics = this.statisticsList[this.statisticsList.length - 1];
          this.todayLearned = latest.learnedCount;
          this.todayTime = latest.studyDuration;
          this.totalGoal = latest.targetCount;
        }
      }
    } catch (error) {
      console.error('Fetch Statistics Error');
    }
  }

  // --- 上传数据：彻底消灭 any ---
  async uploadTodayData(): Promise<void> {
    try {
      const todayData: DailyStatistics = {
        learnedCount: this.todayLearned,
        timeUsed: this.todayTime,
        targetCount: this.totalGoal
      };

      // 核心修改 3：同样给 res 增加显式标注
      const res: AxiosResponse<ApiResponse<null>> = await updateDailyStatistics(todayData);
      const response: ApiResponse<null> = res.data;

      if (response.code === 200) {
        promptAction.showToast({ message: '同步成功' });
        await this.fetchStatistics();
      }
    } catch (error) {
      promptAction.showToast({ message: '同步失败' });
    }
  }

  build() {
    // ... 你的 build 逻辑保持不变 ...
    Column() {
      Row() {
        Text('学习统计').fontSize(22).fontWeight(FontWeight.Bold)
        Blank()
        Button('同步今日数据')
          .onClick(() => { this.uploadTodayData() })
      }.width('100%').padding(20)

      // 列表 KeyGenerator 也要写全类型
      List() {
        ForEach(this.statisticsList, (item: StudyStatistics) => {
          // ... 柱状图代码 ...
        }, (item: StudyStatistics): string => (item.id + item.statDate))
      }
    }
  }

  @Builder StatCard(label: string, value: string, color: string): void {
    // ... 代码 ...
  }
}