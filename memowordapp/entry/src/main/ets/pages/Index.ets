// import { CirclePage } from './CirclePage';
import { MinePage } from './MinePage';
import { PracticePage } from './PracticePage';
import { StudyIndexPage } from './StudyIndexPage';
import{ StatisticsPage } from  './StatisticsPage'
import{AIContent} from  './AIContent'

@Entry
@Component
struct Index {
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  // 【新增】：添加一个全局刷新标志位
  @StorageLink('refreshFlag') refreshFlag: number = 0;

  // Index.ets (主页)
  aboutToAppear() {
    // ✅ 必须有这一步初始化，否则 MinePage 连不到信号
    AppStorage.setOrCreate('needRefreshMine', 0);
  }


  onPageShow() {
    const signal = Date.now();
    console.info("Index: 发送刷新信号 -> " + signal);
    AppStorage.setOrCreate('needRefreshMine', signal);
    this.refreshFlag++;
  }

  build() {
    Tabs({ index: this.currentTabIndex }) {
      TabContent() {
        StudyIndexPage()
      }.tabBar(this.barBuilder(0, '单词', $r('app.media.ic_practice'), $r('app.media.ic_practice_selected')))

      TabContent() {
        StatisticsPage()
      }.tabBar(this.barBuilder(1, '统计', $r('app.media.ic_circle'), $r('app.media.ic_circle_selected')))

      TabContent() {
        MinePage()
      }.tabBar(this.barBuilder(2, '我的', $r('app.media.ic_mine'), $r('app.media.ic_mine_selected')))

      TabContent() {
        AIContent() // <-- 新增的 AI 模块
      }.tabBar('AI 助手') // 这里可以改成你想要的图标和文案


    }.barPosition(BarPosition.End)
    .onChange((index) => {
      this.currentTabIndex = index;
    })
  }

  @Builder
  barBuilder(index: number, title: string, icon: Resource, iconSelect: Resource) {
    Column() {
      Image(this.currentTabIndex === index ? iconSelect : icon)
        .width(25)
        .height(25)
      Text(title)// .fontColor(this.currentIndex == index ? '#0419101' : '#8a8a8a')
        // .fontWeight(FontWeight.Medium)
        .tabTitleStyle(this.currentTabIndex === index ? Color.Black : '#8a8a8a')
    }
  }
}

@Extend(Text)
function tabTitleStyle(color: ResourceColor) {
  .fontSize(10)
  .fontWeight(FontWeight.Medium)
  .fontColor(color)
  .margin({ bottom: 2 })
}