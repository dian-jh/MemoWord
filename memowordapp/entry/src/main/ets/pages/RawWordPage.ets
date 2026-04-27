import { router, promptAction } from '@kit.ArkUI';
import {
  getFavoriteList,
  FavoriteWord,
  toggleFavorite
} from '../http/Api';

@Entry
@Component
struct FavoritePage {
  @State favoriteList: FavoriteWord[] = [];
  @State isLoading: boolean = true;
  @State sortType: number = 0; // 0:时间顺序, 1:时间逆序, 2:字母顺序, 3:字母逆序

  // 颜色常量（沿用项目主题色）
  private readonly PRIMARY_COLOR: string = '#1B9680';
  private readonly BG_COLOR: string = '#F8F7F2';

  async aboutToAppear() {
    await this.loadData();
  }

  // 加载数据
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

  // 排序逻辑
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

  // 取消收藏操作
  async handleToggleFavorite(item: FavoriteWord) {
    try {
      const isFav = await toggleFavorite(item.wordId);
      if (!isFav) {
        // 如果取消成功，从当前 UI 列表移除
        this.favoriteList = this.favoriteList.filter(v => v.wordId !== item.wordId);
        promptAction.showToast({ message: '已移出生词本' });
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败' });
    }
  }

  build() {
    Column() {
      // 1. 导航栏
      this.navBarBuilder()

      Scroll() {
        Column({ space: 20 }) {
          // 2. 收藏信息卡片
          this.infoCardBuilder()

          // 3. 排序切换栏
          this.sortBarBuilder()

          // 4. 单词列表
          if (this.isLoading) {
            Text('加载中...').margin({ top: 50 }).fontColor('#999')
          } else if (this.favoriteList.length === 0) {
            this.emptyStateBuilder()
          } else {
            this.wordListBuilder()
          }
        }
        .width('100%')
        .padding({ bottom: 40 })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.BG_COLOR)
  }

  @Builder
  navBarBuilder() {
    Row() {
      Image($r('app.media.ic_back'))
        .width(24).height(24)
        .onClick(() => router.back())
      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  infoCardBuilder() {
    Column() {
      Row({ space: 15 }) {
        // 1. 左侧封面图
        Image($r('app.media.ic_favorite_cover'))
          .width(80)
          .height(100)
          .borderRadius(6)
          .flexShrink(0)
          .objectFit(ImageFit.Cover)

        // 2. 右侧文字区域：保持正常并自动占据剩余空间
        Column({ space: 8 }) {
          Text('收藏的单词')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`单词数: ${this.favoriteList.length}`)
            .fontSize(14)
            .fontColor('#666')

          // 按钮组
          Row({ space: 10 }) {
            Button('学习')
              .height(32)
              .layoutWeight(1) // 按钮平分右侧剩余空间
              .backgroundColor(this.PRIMARY_COLOR)
              .fontSize(13)
              .borderRadius(16)
              .onClick(() => {
                // 逻辑处理
              })
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .layoutWeight(1) // 【核心】占据除图片外的所有剩余空间，防止文字被顶出屏幕
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFF')
      .borderRadius(12)
      .shadow({
        radius: 12,
        color: '#10000000',
        offsetX: 0,
        offsetY: 6
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
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
    .padding({ left: 16, right: 16 })
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
    Column({ space: 10 }) {
      Image($r('app.media.ic_logo')).width(100).opacity(0.3)
      Text('生词本空空如也').fontColor('#999')
    }
    .width('100%')
    .margin({ top: 100 })
  }
}