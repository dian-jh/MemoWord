import { router, promptAction } from '@kit.ArkUI';
import {
  getFavoriteList,
  FavoriteWord,
  toggleFavorite
} from '../http/Api';
import { StudyMode } from './PracticePage'

@Entry
@Component
struct RawWordPage {
  @State favoriteList: FavoriteWord[] = [];
  @State isLoading: boolean = true;
  @State sortType: number = 0;

  private readonly PRIMARY_COLOR: string = '#1B9680';
  private readonly BG_COLOR: string = '#F8F7F2';

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const data = await getFavoriteList();
      this.favoriteList = data;
      this.sortData();
    } catch (e) {
      promptAction.showToast({ message: '获取收藏列表失败' });
    } finally {
      this.isLoading = false;
    }
  }

  private sortData() {
    if (this.sortType === 0) {
      this.favoriteList.sort((a, b) => new Date(a.createTime).getTime() - new Date(b.createTime).getTime());
    } else if (this.sortType === 1) {
      this.favoriteList.sort((a, b) => new Date(b.createTime).getTime() - new Date(a.createTime).getTime());
    } else if (this.sortType === 2) {
      this.favoriteList.sort((a, b) => a.wordContent.localeCompare(b.wordContent));
    } else if (this.sortType === 3) {
      this.favoriteList.sort((a, b) => b.wordContent.localeCompare(a.wordContent));
    }
  }

  build() {
    // 【关键改动 1】根容器必须设置 alignItems 为 Start，justifyContent 为 Start
    Column() {
      // 1. 顶部导航
      this.navBarBuilder()

      // 2. 滚动区域
      Scroll() {
        // 【关键改动 2】这里的 Column 不要设置 space，手动控制间距
        Column() {
          // 2.1 统计卡片
          this.infoCardBuilder()

          // 2.2 排序栏
          this.sortBarBuilder()

          // 2.3 内容主体
          if (this.isLoading) {
            Text('加载中...').margin({ top: 30 }).fontColor('#999')
          } else if (this.favoriteList.length === 0) {
            this.emptyStateBuilder()
          } else {
            this.wordListBuilder()
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start) // 确保内部子项从顶部开始排
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1) // 撑满剩余屏幕高度
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .align(Alignment.Top) // 【关键改动 3】确保 Scroll 内部对齐方式为顶部
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.BG_COLOR)
    .justifyContent(FlexAlign.Start) // 【核心】确保所有子组件从屏幕最上方开始堆叠
  }

  @Builder
  navBarBuilder() {
    Row() {
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .onClick(() => router.back())
    }
    .width('100%')
    .height(56) // 稍微加高一点，符合标准导航栏视觉
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.BG_COLOR)
  }

  @Builder
  infoCardBuilder() {
    // 【关键改动 4】移除所有可能导致下移的 padding-top
    Column() {
      Row({ space: 15 }) {
        Image($r('app.media.ic_favorite_cover'))
          .width(80)
          .height(100)
          .borderRadius(6)
          .flexShrink(0)
          .objectFit(ImageFit.Cover)

        Column({ space: 8 }) {
          Text('收藏的单词')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000')

          Text(`单词数: ${this.favoriteList.length}`)
            .fontSize(14)
            .fontColor('#666')

          Button('学习')
            .height(32)
            .width('100%')
            .backgroundColor(this.PRIMARY_COLOR)
            .fontSize(13)
            .borderRadius(16)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/PracticePage',
                params: { mode: StudyMode.FAVORITE }
              })
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFF')
      .borderRadius(12)
      .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 8 }) // 仅保留 10 的间距
  }

  @Builder
  sortBarBuilder() {
    Row() {
      ForEach(['时间顺序', '时间逆序', '字母顺序', '字母逆序'], (label: string, index: number) => {
        Text(label)
          .fontSize(12)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.sortType === index ? '#E8F5F2' : '#F2F2F2')
          .fontColor(this.sortType === index ? this.PRIMARY_COLOR : '#666')
          .borderRadius(15)
          .margin({ right: 8 })
          .onClick(() => {
            this.sortType = index;
            this.sortData();
          })
      }, (item: string) => item)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  wordListBuilder() {
    Column() {
      ForEach(this.favoriteList, (item: FavoriteWord) => {
        Column() {
          Row() {
            Column({ space: 4 }) {
              Text(item.wordContent).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#000')
              Text(item.translation || '暂无释义').fontSize(14).fontColor('#888').maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row({ space: 15 }) {
              // 详情入口
              Row() {
                Text('详情').fontSize(12).fontColor('#999')
                Image($r('app.media.ic_arrow_right')).width(12).height(12).fillColor('#CCC')
              }
              .onClick(() => {
                router.pushUrl({ url: 'pages/WordDetailPage', params: { wordId: item.wordId } })
              })
            }
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })

          Divider().color('#F0F0F0').strokeWidth(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .backgroundColor('#FFF')
      }, (item: FavoriteWord) => item.wordId.toString())
    }
  }


  @Builder
  emptyStateBuilder() {
    Column() {
      Text('生词本空空如也')
        .fontColor('#999')
        .fontSize(14)
        .margin({ top: 40 }) // 稍微带一点间距，但绝不居中
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}