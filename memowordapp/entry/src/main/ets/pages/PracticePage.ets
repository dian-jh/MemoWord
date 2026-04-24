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

// 【新增】：用于富文本高亮渲染的接口
interface TextSegment {
  id: string;
  text: string;
  isHighlight: boolean;
}

@Entry
@Component
export struct PracticePage {
  @StorageLink('currentTabIndex') currentTabIndex: number = 0

  // ---------------- 状态变量 ----------------
  @State todayTarget: number = 0
  @State learnedCount: number = 0
  @State wordQueue: StudyWord[] = []

  @State currentParsedExamples: ExampleSentence[] = []
  @State currentParsedExchanges: ParsedExchange[] = []

  @State isRevealed: boolean = false
  @State isLoading: boolean = true

  // ---------------- 内部追踪变量 ----------------
  private sessionStartTime: number = 0;
  private initialDuration: number = 0;
  private sessionLearnedCount: number = 0;
  private isSyncing: boolean = false;

  aboutToAppear(): void {
    this.startSession()
  }

  private async startSession(): Promise<void> {
    this.isLoading = true
    try {
      this.todayTarget = await getTodayTargetCount();
      this.learnedCount = await getTodayLearnedCount();
      this.initialDuration = await getTodayStudyDuration();

      this.sessionLearnedCount = 0;
      this.sessionStartTime = Date.now();

      const remainCount: number = this.todayTarget - this.learnedCount;
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

  private onKnow(): void {
    if (this.wordQueue.length === 0) return;
    const finishedWord: StudyWord = this.wordQueue[0];
    this.wordQueue = this.wordQueue.slice(1);
    this.learnedCount += 1;
    this.sessionLearnedCount += 1;
    console.info('MemoWord_Debug', `[Mastered] 学会了: ${finishedWord.wordContent}, 今日进度: ${this.learnedCount}`);
    if (this.wordQueue.length > 0) {
      this.updateCurrentWordState();
    } else {
      this.syncProgressAndExit();
    }
  }

  private onUnknown(): void {
    if (this.wordQueue.length === 0) return;
    const currentWord: StudyWord = this.wordQueue[0];
    const remainingQueue: StudyWord[] = this.wordQueue.slice(1);
    this.wordQueue = [...remainingQueue, currentWord];
    console.info('MemoWord_Debug', `[Recycle] 不认识: ${currentWord.wordContent}, 移至队尾重学`);
    this.updateCurrentWordState();
  }

  onBackPress(): boolean {
    if (this.isSyncing) return true;
    this.syncProgressAndExit();
    return true;
  }

  private async syncProgressAndExit(): Promise<void> {
    if (this.isSyncing) return;
    this.isSyncing = true;
    this.isLoading = true;

    const sessionMs: number = Date.now() - this.sessionStartTime;
    let addedMinutes: number = 0;

    if (sessionMs >= 60000) {
      addedMinutes = Math.round(sessionMs / 60000);
    } else if (sessionMs >= 10000 && this.sessionLearnedCount > 0) {
      addedMinutes = 1;
    }

    const finalDuration: number = this.initialDuration + addedMinutes;

    try {
      if (this.sessionLearnedCount > 0 || addedMinutes > 0) {
        console.info('MemoWord_Debug', `[Exit] 正在同步数据...`);
        await setTodayLearnedCount(this.learnedCount);
        await setTodayStudyDuration(finalDuration);
        console.info('MemoWord_Debug', `[Exit] 同步成功`);
      }
    } catch (error) {
      console.error('MemoWord_Debug', '[Exit] 同步失败', JSON.stringify(error));
      promptAction.showToast({ message: '进度同步异常，请检查网络' });
    } finally {
      this.isSyncing = false;
      try { router.back(); } catch {}
    }
  }

  // ---------------- 工具方法 ----------------
  private updateCurrentWordState(): void {
    this.isRevealed = false
    if (this.wordQueue.length > 0) {
      const word: StudyWord = this.wordQueue[0];
      this.currentParsedExamples = this.parseExampleSentences(word.exampleSentences, word.id.toString());
      this.currentParsedExchanges = parseWordExchanges(word.wordExchanges);
    }
  }

  private getProgress(): number {
    return this.todayTarget > 0 ? this.learnedCount / this.todayTarget : 0;
  }

  private getMeaningLines(word: StudyWord): string[] {
    const lines: string[] = [];
    const splitLine = (str: string): string[] => {
      let arr: string[] = str.split('\\n');
      if (arr.length <= 1) {
        arr = str.split('\n');
      }
      return arr.map((item: string) => item.trim())
        .filter((item: string) => item.length > 0);
    };

    if (word.translation) {
      const transList: string[] = splitLine(word.translation);
      lines.push(...transList);
    }
    if (word.definition) {
      const defList: string[] = splitLine(word.definition);
      lines.push(...defList);
    }
    return lines.length > 0 ? lines : ['暂无释义'];
  }

  private parseExampleSentences(raw: string | null | undefined, wordId: string): ExampleSentence[] {
    if (!raw) return []
    const segments: string[] = raw.split('<br>').map(i => i.trim()).filter(i => i.length > 0)
    const sentenceList: ExampleSentence[] = []
    let currentEn = ''

    for (let i = 0; i < segments.length; i++) {
      const segment = segments[i]
      const hasChinese = /[\u4e00-\u9fa5]/.test(segment)

      if (!hasChinese) {
        currentEn = segment
      } else {
        if (currentEn !== '') {
          sentenceList.push({
            id: `${wordId}-${sentenceList.length}`,
            en: currentEn,
            zh: segment
          })
          currentEn = ''
        }
      }
    }
    return sentenceList.slice(0, 3)
  }

  // 【新增】：根据目标单词切割英文句子，返回一段段可渲染的 Span 数组
  private getHighlightedSegments(sentence: string, targetWord: string): TextSegment[] {
    if (!targetWord || !sentence) {
      return [{ id: '0', text: sentence, isHighlight: false }];
    }
    // 转义正则特殊字符，防止报错，并使用忽略大小写 'i'
    const escapedWord = targetWord.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(${escapedWord})`, 'i');

    // split 时正则带括号，会把匹配到的单词也保留在数组里
    const parts = sentence.split(regex);
    const segments: TextSegment[] = [];

    for (let i = 0; i < parts.length; i++) {
      if (parts[i].length > 0) {
        segments.push({
          id: `${i}-${parts[i]}`,
          text: parts[i],
          // 如果当前片段转小写等于目标单词，则判定为需要高亮
          isHighlight: parts[i].toLowerCase() === targetWord.toLowerCase()
        });
      }
    }
    return segments;
  }

  // ---------------- UI 构建 ----------------
  build() {
    Column() {
      this.headerBuilder()

      if (this.isLoading && this.isSyncing) {
        this.statusPageBuilder('保存中...', '正在同步您的学习进度', false)
      } else if (this.isLoading && !this.isSyncing) {
        this.statusPageBuilder('准备中...', '正在为您加载单词', false)
      } else if (this.wordQueue.length === 0) {
        this.statusPageBuilder('今日目标已完成', '太棒了，进度已全部同步', true)
      } else {
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
          .width(26).height(26).fillColor('#000000')
          .onClick(() => this.syncProgressAndExit())

        Text(`${this.learnedCount} / ${this.todayTarget}`)
          .fontSize(18).fontWeight(700).fontColor('#000000').layoutWeight(1).textAlign(TextAlign.Center)

        Blank().width(26)
      }
      .width('100%').height(56).padding({ left: 16, right: 16 })

      Stack({ alignContent: Alignment.Start }) {
        Row().width('100%').height(6).backgroundColor('#E5E5E5').borderRadius(3)
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

          if (this.isRevealed) {
            this.meaningBuilder()
          }

          if (this.isRevealed && this.currentParsedExchanges.length > 0) {
            this.exchangesBuilder()
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
          Text('点击屏幕显示释义').fontSize(15).fontColor('#555555').margin({ bottom: 24 }).opacity(0.8)
        }
      }
    }
    .width('100%').layoutWeight(1)
  }

  @Builder
  private wordDisplayBuilder() {
    Column({ space: 12 }) {
      Text(this.wordQueue[0].wordContent)
        .fontSize(35)
        .fontWeight(FontWeight.Bold)
        // 【修改点 1】：顶部主单词改为 #1B9680 主题绿
        .fontColor('#1B9680')
        .textAlign(TextAlign.Center)
        .width('100%')

      if (this.wordQueue[0].phoneticUs) {
        Text(`美 [${this.wordQueue[0].phoneticUs.replace(/\[|\]/g, '')}]`).phoneticStyle()
      }
    }
    .width('100%').padding({ top: 16, bottom: 8 })
  }

  @Builder
  private meaningBuilder() {
    Column({ space: 8 }) {
      ForEach(this.getMeaningLines(this.wordQueue[0]), (line: string, index: number) => {
        Text(line)
          .fontSize(16)
          .lineHeight(26)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .width('100%')
          .textAlign(TextAlign.Start)
      }, (line: string, index: number) => index.toString())
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FAFAFA')
    .borderRadius(20)
  }

  @Builder
  private exchangesBuilder() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.currentParsedExchanges, (exchange: ParsedExchange, index: number) => {
        Row({ space: 6 }) {
          Text(exchange.label).fontSize(12).fontColor('#555555')
          Text(exchange.word).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#000000')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 }).backgroundColor('#F5F5F5').borderRadius(8).margin({ right: 8, bottom: 8 })
      }, (exchange: ParsedExchange, index: number) => index.toString())
    }
    .width('100%').padding(16).backgroundColor('#FAFAFA').borderRadius(20)
  }

  @Builder
  private examplesBuilder() {
    Column({ space: 12 }) {
      Text('例句').fontSize(16).fontWeight(700).fontColor('#000000').width('100%')

      ForEach(this.currentParsedExamples, (item: ExampleSentence) => {
        Column({ space: 6 }) {

          // 【修改点 2】：放弃单一 Text(item.en)，改用 Text + Span 组合渲染
          Text() {
            ForEach(this.getHighlightedSegments(item.en, this.wordQueue[0]?.wordContent || ''), (seg: TextSegment) => {
              Span(seg.text)
              // 如果 isHighlight 为 true，则赋予 #1B9680，并加粗
                .fontColor(seg.isHighlight ? '#1B9680' : '#000000')
                .fontWeight(seg.isHighlight ? FontWeight.Bold : FontWeight.Medium)
            }, (seg: TextSegment) => seg.id)
          }
          .fontSize(15).lineHeight(22).width('100%')

          if (this.isRevealed && item.zh) {
            Text(item.zh).fontSize(14).lineHeight(20).fontColor('#555555').width('100%')
          }
        }
        .width('100%').padding(12).backgroundColor('#F5F5F5').borderRadius(16).margin({ bottom: 6 })
      }, (item: ExampleSentence) => item.id)
    }
    .width('100%').padding(16).backgroundColor('#FAFAFA').borderRadius(20)
  }

  @Builder
  private bottomActionBuilder() {
    Row({ space: 0 }) {
      Column({ space: 6 }) {
        Text('认识')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .textAlign(TextAlign.Center)

        Row().width(20).height(6).borderRadius(5).backgroundColor('#1FBE93')
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .onClick(() => this.onKnow())

      Column({ space: 6 }) {
        Text('不认识')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
          .textAlign(TextAlign.Center)

        Row().width(20).height(6).borderRadius(5).backgroundColor('#FF6B6B')
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .onClick(() => this.onUnknown())
    }
    .width('100%').padding({ left: 40, right: 40, bottom: 32, top: 12 })
  }

  @Builder
  private statusPageBuilder(title: string, sub: string, showBtn: boolean) {
    Column({ space: 16 }) {
      Text(title).fontSize(24).fontColor('#000000').fontWeight(FontWeight.Bold)
      Text(sub).fontSize(15).fontColor('#555555').textAlign(TextAlign.Center)
      if (showBtn) {
        Button('返回主页').width(180).height(50).borderRadius(25).backgroundColor('#1FBE93').onClick(() => this.syncProgressAndExit())
      }
    }
    .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).padding(16)
  }
}

@Extend(Column) function pageStyle() {
  .width('100%').height('100%').backgroundColor('#F8F7F2')
}
@Extend(Text) function phoneticStyle() {
  .fontSize(15).fontColor('#555555').fontWeight(FontWeight.Medium)
}