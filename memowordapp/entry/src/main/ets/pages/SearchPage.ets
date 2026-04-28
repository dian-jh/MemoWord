// src/main/ets/pages/SearchPage.ets
import { router, promptAction } from '@kit.ArkUI';
import {
  searchWords,
  SearchWordResult,
  getSearchHistory,
  clearSearchHistory,
  addSearchHistory,
  SearchHistoryDto
} from '../http/Api';
import { BusinessError } from '@ohos.base';

@Entry
@Component
struct SearchPage {
  @State searchText: string = '';
  @State matchWordList: SearchWordResult[] = [];
  @State historyList: SearchHistoryDto[] = []; // 搜索历史状态
  @StorageLink('token') token: string = '';

  // 页面进入时加载历史记录
  async aboutToAppear(): Promise<void> {
    await this.refreshHistory();
  }

  // 封装刷新历史逻辑
  private async refreshHistory(): Promise<void> {
    if (this.token) {
      try {
        // 后端已按时间倒序排序，前端直接接收展示
        this.historyList = await getSearchHistory();
      } catch (err) {
        const error = err as BusinessError;
        console.error("SearchPage: 加载历史失败", error.message);
      }
    }
  }

  // 实时搜索逻辑
  private async onSearch(): Promise<void> {
    const keyword: string = this.searchText.trim();
    if (keyword.length > 0) {
      try {
        const list: SearchWordResult[] = await searchWords(keyword);
        this.matchWordList = list;
      } catch (err) {
        this.matchWordList = [];
      }
    } else {
      this.matchWordList = [];
      await this.refreshHistory();
    }
  }

  // 点击单词：保存历史并跳转
  private async handleWordClick(id: number): Promise<void> {
    if (this.token) {
      // 静默添加，不阻塞跳转体验
      addSearchHistory(id).catch((err: BusinessError) => {
        console.warn("SearchPage: 记录历史失败", err.message);
      });
    }
    router.pushUrl({ url: 'pages/WordDetailPage', params: { wordId: id } });
  }

  // 清空历史
  private async handleClearHistory(): Promise<void> {
    try {
      const success: boolean = await clearSearchHistory();
      if (success) {
        this.historyList = [];
        promptAction.showToast({ message: '搜索历史已清空' });
      }
    } catch (err) {
      promptAction.showToast({ message: '清空失败' });
    }
  }

  build() {
    Column() {
      // 1. 顶部搜索栏
      this.searchHeaderBuilder()

      // 2. 动态内容区
      if (this.searchText.trim().length === 0) {
        // 场景 A：无输入 -> 显示搜索历史
        this.historySectionBuilder()
      } else if (this.matchWordList.length === 0) {
        // 场景 B：有输入但无结果
        this.emptyStateBuilder()
      } else {
        // 场景 C：有输入且有结果 -> 显示搜索列表
        this.resultListBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  @Builder
  searchHeaderBuilder() {
    Row() {
      TextInput({ text: this.searchText, placeholder: "搜索单词" })
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#f5f5f5')
        .borderRadius(20)
        .padding({ left: 14, right: 14 })
        .fontSize(16)
        .onChange(async (value: string) => {
          this.searchText = value;
          await this.onSearch();
        });

      Text("取消")
        .margin({ left: 10 })
        .onClick(() => router.back());
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  historySectionBuilder() {
    Column() {
      Row() {
        Text("搜索历史")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        // 清空图标
        Image($r('app.media.ic_delete')) // 请确保资源库有此垃圾桶图标
          .width(22).height(22).opacity(0.4)
          .onClick(() => this.handleClearHistory())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })

      List() {
        ForEach(this.historyList, (item: SearchHistoryDto) => {
          ListItem() {
            this.wordItemBuilder(item)
          }
        }, (item: SearchHistoryDto) => item.id.toString() + item.createTime)
      }.layoutWeight(1)
    }
    .width('100%').layoutWeight(1)
  }

  @Builder
  resultListBuilder() {
    List() {
      ForEach(this.matchWordList, (item: SearchWordResult) => {
        ListItem() {
          this.wordItemBuilder(item)
        }
      }, (item: SearchWordResult) => item.id.toString())
    }
    .layoutWeight(1).width('100%')
  }

  @Builder
  wordItemBuilder(item: SearchWordResult) { // ✅ 直接传入整个对象，方便获取所有字段
    Column() {
      // 第一行：单词 + 音标
      Row({ space: 8 }) { // 设置单词和音标之间的间距
        Text(item.wordContent)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        if (item.phoneticUs) {
          Text(`/${item.phoneticUs.replace(/\//g, '')}/`) // 自动处理斜杠，确保格式统一
            .fontSize(14)      // ✅ 字体更小
            .fontColor('#999') // ✅ 颜色更淡
            .fontWeight(FontWeight.Normal)
            .margin({ left: 10 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom) // ✅ 让音标基线对齐单词底部，更美观

      // 第二行：释义
      Text(item.translation ?? '')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 6 })
        .maxLines(1) // 限制一行显示，多出部分隐藏（类似参考图效果）
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => this.handleWordClick(item.id))
  }

  @Builder
  emptyStateBuilder() {
    Column() {
      Text("未找到相关内容").fontSize(17).fontColor("#999")
    }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
  }
}