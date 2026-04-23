import { promptAction, router } from '@kit.ArkUI'
import {
  getTodayTargetCount,
  getTodayWordQueue,
  getTodayLearnedCount,
  getTodayStudyDuration,
  setTodayLearnedCount,
  setTodayStudyDuration,
  StudyWord
} from '../http/Api'
import { parseWordExchanges, ParsedExchange } from '../utils/parseWordExchangesUtil'

interface ExampleSentence {
  id: string
  en: string
  zh: string
}

@Entry
@Component
export struct PracticePage {
  @StorageLink('currentTabIndex') currentTabIndex: number = 0

  // ---------------- 状态变量 ----------------
  @State todayTarget: number = 0
  @State learnedCount: number = 0 // UI 上显示的今日已学总数
  @State wordQueue: StudyWord[] = [] // 待学习队列

  @State currentParsedExamples: ExampleSentence[] = []
  @State currentParsedExchanges: ParsedExchange[] = []

  @State isRevealed: boolean = false
  @State isLoading: boolean = true

  // ---------------- 内部追踪变量 ----------------
  private sessionStartTime: number = 0;
  private initialDuration: number = 0;
  private sessionLearnedCount: number = 0; // 本次页面内新学会的单词数
  private isSyncing: boolean = false;

  aboutToAppear(): void {
    this.startSession()
  }

  /**
   * 1. 初始化会话
   */
  private async startSession(): Promise<void> {
    this.isLoading = true
    try {
      // 【核心修复】：拆解 Promise.all，按顺序获取，照顾模拟器的网络栈
      this.todayTarget = await getTodayTargetCount();
      this.learnedCount = await getTodayLearnedCount();
      this.initialDuration = await getTodayStudyDuration();

      this.sessionLearnedCount = 0;
      this.sessionStartTime = Date.now();

      const remainCount = this.todayTarget - this.learnedCount;
      if (remainCount > 0) {
        this.wordQueue = await getTodayWordQueue(remainCount);
        this.updateCurrentWordState();
      } else {
        this.wordQueue = [];
      }
    } catch (error) {
      console.error('MemoWord_Debug', '[Session] 启动失败', JSON.stringify(error));
      promptAction.showToast({ message: '加载学习数据失败' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 2. 逻辑：认识（移除并计数）
   */
  private onKnow(): void {
    if (this.wordQueue.length === 0) return;

    // A. 从队列中移除当前词
    const finishedWord = this.wordQueue[0];
    this.wordQueue = this.wordQueue.slice(1);

    // B. 更新计数器（今日总数 + 本次会话数）
    this.learnedCount += 1;
    this.sessionLearnedCount += 1;

    console.info('MemoWord_Debug', `[Mastered] 学会了: ${finishedWord.wordContent}, 今日进度: ${this.learnedCount}`);

    // C. 切换到下一个词
    if (this.wordQueue.length > 0) {
      this.updateCurrentWordState();
    } else {
      // 队列清空，自动同步并完成
      this.syncProgressAndExit();
    }
  }

  /**
   * 3. 逻辑：不认识（扔到队尾，不计数）
   */
  private onUnknown(): void {
    if (this.wordQueue.length === 0) return;

    // A. 提取当前词并从头部切除
    const currentWord = this.wordQueue[0];
    const remainingQueue = this.wordQueue.slice(1);

    // B. 拼接到队列末尾，实现循环
    this.wordQueue = [...remainingQueue, currentWord];

    console.info('MemoWord_Debug', `[Recycle] 不认识: ${currentWord.wordContent}, 移至队尾重学`);

    // C. 重置展示状态，刷新内容
    this.updateCurrentWordState();
  }

  /**
   * 4. 退出拦截（侧滑/物理返回）
   */
  onBackPress(): boolean {
    if (this.isSyncing) return true;
    this.syncProgressAndExit();
    return true;
  }

  /**
   * 5. 核心同步逻辑
   */
  private async syncProgressAndExit(): Promise<void> {
    if (this.isSyncing) return;
    this.isSyncing = true;
    this.isLoading = true;

    const sessionMs = Date.now() - this.sessionStartTime;
    let addedMinutes = 0;

    if (sessionMs >= 60000) {
      addedMinutes = Math.round(sessionMs / 60000);
    } else if (sessionMs >= 10000 && this.sessionLearnedCount > 0) {
      addedMinutes = 1;
    }

    const finalDuration = this.initialDuration + addedMinutes;

    try {
      if (this.sessionLearnedCount > 0 || addedMinutes > 0) {
        console.info('MemoWord_Debug', `[Exit] 正在同步数据...`);

        // 【核心修复】：拆解 Promise.all，改为 await 串行执行
        // 先等第一个接口彻底落库完成
        await setTodayLearnedCount(this.learnedCount);
        // 再发第二个接口，完美规避 EF Core 并发异常
        await setTodayStudyDuration(finalDuration);

        console.info('MemoWord_Debug', `[Exit] 同步成功`);
      }
    } catch (e) {
      console.error('MemoWord_Debug', '[Exit] 同步失败', JSON.stringify(e));
      promptAction.showToast({ message: '进度同步异常，请检查网络' });
    } finally {
      this.isSyncing = false;
      try { router.back(); } catch (e) { this.currentTabIndex = 0; }
    }
  }

  // ---------------- 工具方法 ----------------

  private updateCurrentWordState(): void {
    this.isRevealed = false
    if (this.wordQueue.length > 0) {
      const word = this.wordQueue[0];
      this.currentParsedExamples = this.parseExampleSentences(word.exampleSentences, word.id.toString());
      this.currentParsedExchanges = parseWordExchanges(word.wordExchanges);
    }
  }

  private getProgress(): number {
    return this.todayTarget > 0 ? this.learnedCount / this.todayTarget : 0;
  }

  private getMeaningText(word: StudyWord): string {
    const meaning: string[] = []
    if (word.translation) meaning.push(word.translation)
    if (word.definition) meaning.push(word.definition)
    return meaning.length > 0 ? meaning.join('\n') : '暂无释义'
  }

  private parseExampleSentences(raw: string | null | undefined, wordId: string): ExampleSentence[] {
    if (!raw) return []
    const segments: string[] = raw.split('<br>').map(i => i.trim()).filter(i => i.length > 0).slice(0, 6)
    const sentenceList: ExampleSentence[] = []
    for (let i = 0; i < segments.length; i += 2) {
      sentenceList.push({ id: `${wordId}-${i}`, en: segments[i], zh: i + 1 < segments.length ? segments[i + 1] : '' })
    }
    return sentenceList
  }

  // ---------------- UI 构建 ----------------

  build() {
    Column() {
      // 头部
      this.headerBuilder()

      if (this.isLoading && this.isSyncing) {
        this.statusPageBuilder('保存中...', '正在同步您的学习进度', false)
      } else if (this.isLoading && !this.isSyncing) {
        this.statusPageBuilder('准备中...', '正在为您加载单词', false)
      } else if (this.wordQueue.length === 0) {
        this.statusPageBuilder('今日目标已完成', '太棒了，进度已全部同步', true)
      } else {
        // 主练习区
        this.practiceContentBuilder()
      }
    }
    .pageStyle()
  }

  @Builder
  private headerBuilder() {
    Column() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(26).height(26).fillColor('#FFFFFF')
          .onClick(() => this.syncProgressAndExit())

        Text(`${this.learnedCount} / ${this.todayTarget}`)
          .fontSize(18).fontWeight(700).fontColor('#FFFFFF').layoutWeight(1).textAlign(TextAlign.Center)

        Blank().width(26)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })

      Stack({ alignContent: Alignment.Start }) {
        Row().width('100%').height(6).backgroundColor('#2A2A2D').borderRadius(3)
        Row().width(`${Math.min(this.getProgress() * 100, 100)}%`).height(6).backgroundColor('#1FBE93').borderRadius(3)
      }
      .width('100%').padding({ left: 20, right: 20, bottom: 8 })
    }
  }

  @Builder
  private practiceContentBuilder() {
    Column() {
      Scroll() {
        Column({ space: 12 }) {
          this.wordDisplayBuilder()
          if (this.isRevealed && this.currentParsedExchanges.length > 0) {
            this.exchangesBuilder()
          }
          if (this.isRevealed) {
            this.meaningBuilder()
          }
          if (this.currentParsedExamples.length > 0) {
            this.examplesBuilder()
          }
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .onClick(() => { if (!this.isRevealed) this.isRevealed = true })

      Column() {
        if (this.isRevealed) {
          this.bottomActionBuilder()
        } else {
          Text('点击屏幕显示释义').fontSize(15).fontColor('#888').margin({ bottom: 24 }).opacity(0.8)
        }
      }
    }
    .width('100%').layoutWeight(1)
  }

  @Builder
  private wordDisplayBuilder() {
    Column({ space: 12 }) {
      Text(this.wordQueue[0].wordContent).fontSize(35).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').textAlign(TextAlign.Center).width('100%')
      if (this.wordQueue[0].phoneticUs) {
        Text(`美 [${this.wordQueue[0].phoneticUs.replace(/\[|\]/g, '')}]`).phoneticStyle()
      }
    }
    .width('100%').padding({ top: 16, bottom: 8 })
  }

  @Builder
  private exchangesBuilder() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.currentParsedExchanges, (exchange: ParsedExchange) => {
        Row({ space: 6 }) {
          Text(exchange.label).fontSize(12).fontColor('#9AA7B4')
          Text(exchange.word).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#DCE5EE')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 }).backgroundColor('#2C2C30').borderRadius(8).margin({ right: 8, bottom: 8 })
      }, (item: ParsedExchange, index: number) => index.toString())
    }
    .width('100%').padding(16).backgroundColor('#252528').borderRadius(20)
  }

  @Builder
  private meaningBuilder() {
    Column() {
      Text(this.getMeaningText(this.wordQueue[0])).fontSize(16).lineHeight(26).fontWeight(FontWeight.Medium).fontColor('#F0F0F0').width('100%').textAlign(TextAlign.Center)
    }
    .width('100%').padding(16).backgroundColor('#252528').borderRadius(20)
  }

  @Builder
  private examplesBuilder() {
    Column({ space: 12 }) {
      Text('例句').fontSize(16).fontWeight(700).fontColor('#DDDDDD').width('100%')
      ForEach(this.currentParsedExamples, (item: ExampleSentence) => {
        Column({ space: 6 }) {
          Text(item.en).fontSize(15).lineHeight(22).fontColor('#FFFFFF').width('100%').fontWeight(500)
          if (this.isRevealed && item.zh) {
            Text(item.zh).fontSize(14).lineHeight(20).fontColor('#A8A8A8').width('100%')
          }
        }
        .width('100%').padding(12).backgroundColor('#2C2C30').borderRadius(16).margin({ bottom: 6 })
      }, (item: ExampleSentence) => item.id)
    }
    .width('100%').padding(16).backgroundColor('#252528').borderRadius(20)
  }

  @Builder
  private bottomActionBuilder() {
    Row({ space: 16 }) {
      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_wrong')).width(22).height(22).fillColor('#FF6B6B')
          Text('不认识').fontSize(17).fontColor('#FF6B6B').fontWeight(700)
        }.justifyContent(FlexAlign.Center).width('100%')
      }.actionBtnStyle('#332323').onClick(() => this.onUnknown())

      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.ic_right')).width(22).height(22).fillColor('#4ADE80')
          Text('认识').fontSize(17).fontColor('#4ADE80').fontWeight(700)
        }.justifyContent(FlexAlign.Center).width('100%')
      }.actionBtnStyle('#233329').onClick(() => this.onKnow())
    }
    .width('100%').padding({ left: 16, right: 16, bottom: 24, top: 12 })
  }

  @Builder
  private statusPageBuilder(title: string, sub: string, showBtn: boolean) {
    Column({ space: 16 }) {
      Text(title).fontSize(24).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      Text(sub).fontSize(15).fontColor('#999').textAlign(TextAlign.Center)
      if (showBtn) {
        Button('返回主页').width(180).height(50).borderRadius(25).backgroundColor('#1FBE93').onClick(() => this.syncProgressAndExit())
      }
    }
    .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).padding(16)
  }
}

@Extend(Column) function pageStyle() { .width('100%').height('100%').backgroundColor('#121212') }
@Extend(Text) function phoneticStyle() { .fontSize(15).fontColor('#BBBBBB').fontWeight(FontWeight.Medium) }
@Extend(Button) function actionBtnStyle(bg: string) { .layoutWeight(1).height(54).backgroundColor(bg).borderRadius(27).type(ButtonType.Normal) }