// import { CirclePage } from './CirclePage';
import { MinePage } from './MinePage';
import { PracticePage } from './PracticePage';
import { StudyIndexPage } from './StudyIndexPage';
import{ StatisticsPage } from  './StatisticsPage'

@Entry
@Component
struct Index {
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  // 【新增】：添加一个全局刷新标志位
  @StorageLink('refreshFlag') refreshFlag: number = 0;

  onPageShow() {
    // 当从 SplashPage 进入，或者从 PracticePage router.back() 返回时，这里会被触发
    // 每次显示，让标志位 +1，触发子组件的 @Watch 监听
    this.refreshFlag++;
  }

  build() {
    Tabs({ index: this.currentTabIndex }) {
      TabContent() {
        StudyIndexPage()
      }.tabBar(this.barBuilder(0, '单词', $r('app.media.ic_practice'), $r('app.media.ic_practice_selected')))

      TabContent() {
        StatisticsPage()
      }.tabBar(this.barBuilder(1, '圈子', $r('app.media.ic_circle'), $r('app.media.ic_circle_selected')))

      TabContent() {
        MinePage()
      }.tabBar(this.barBuilder(2, '我的', $r('app.media.ic_mine'), $r('app.media.ic_mine_selected')))
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