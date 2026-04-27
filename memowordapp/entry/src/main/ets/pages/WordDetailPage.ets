import { promptAction, router } from '@kit.ArkUI'
import {
  StudyWord,
  WordWithFavorite,
  getWordDetail
} from '../http/Api'
import { parseWordExchanges, ParsedExchange } from '../utils/parseWordExchangesUtil'

interface ExampleSentence {
  id: string
  en: string
  zh: string
}

interface TextSegment {
  id: string;
  text: string;
  isHighlight: boolean;
}

// 定义跳转参数的精确类型
interface RouterParams {
  word?: WordWithFavorite;
  wordId?: number;
}

@Entry
@Component
struct WordDetailPage {
  // 从上一个页面路由传参获取单词数据
  @State wordData: WordWithFavorite | null = null
  @State currentParsedExamples: ExampleSentence[] = []
  @State currentParsedExchanges: ParsedExchange[] = []
  @State isLoading: boolean = true

  async aboutToAppear() {
    this.isLoading = true

    // 1. 获取参数并转换为定义的 RouterParams 接口类型
    const params = router.getParams() as RouterParams;

    // 2. 使用可选链或非空判断安全访问属性
    if (params) {
      if (params.word) {
        // 场景1：直接从列表带入了完整单词数据
        this.wordData = params.word;
        this.initParsedContent();
      } else if (params.wordId) {
        // 场景2：通过 ID 异步获取
        try {
          const detail = await getWordDetail(params.wordId);
          if (detail) {
            this.wordData = detail;
            this.initParsedContent();
          }
        } catch (e) {
          promptAction.showToast({ message: '获取详情失败' });
        }
      }
    }

    this.isLoading = false;
  }

  // 这个方法的作用是：当 wordData 获取成功后，统一触发解析逻辑
  private initParsedContent(): void {
    if (this.wordData && this.wordData.word) {
      const word = this.wordData.word;
      // 1. 调用你之前定义的 parseExampleSentences 解析例句
      this.currentParsedExamples = this.parseExampleSentences(word.exampleSentences, word.id.toString());
      // 2. 调用 utils 里的 parseWordExchanges 解析词形变化
      this.currentParsedExchanges = parseWordExchanges(word.wordExchanges);
    }
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
          sentenceList.push({ id: `${wordId}-${sentenceList.length}`, en: currentEn, zh: segment })
          currentEn = ''
        }
      }
    }
    return sentenceList.slice(0, 3)
  }

  private getHighlightedSegments(sentence: string, targetWord: string): TextSegment[] {
    if (!targetWord || !sentence) return [{ id: '0', text: sentence, isHighlight: false }];
    const escapedWord = targetWord.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(${escapedWord})`, 'i');
    const parts = sentence.split(regex);
    const segments: TextSegment[] = [];
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].length > 0) {
        segments.push({
          id: `${i}-${parts[i]}`,
          text: parts[i],
          isHighlight: parts[i].toLowerCase() === targetWord.toLowerCase()
        });
      }
    }
    return segments;
  }

  private getMeaningLines(word: StudyWord): string[] {
    const lines: string[] = [];
    const splitLine = (str: string): string[] => {
      let arr: string[] = str.split('\\n');
      if (arr.length <= 1) arr = str.split('\n');
      return arr.map((item: string) => item.trim()).filter((item: string) => item.length > 0);
    };
    if (word.translation) lines.push(...splitLine(word.translation));
    if (word.definition) lines.push(...splitLine(word.definition));
    return lines.length > 0 ? lines : ['暂无释义'];
  }

  build() {
    Column() {
      // 头部
      this.headerBuilder()

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#1B9680')
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.wordData) {
        Scroll() {
          Column({ space: 16 }) {
            // 1. 单词与音标
            this.wordDisplayBuilder()

            // 2. 释义区
            this.meaningBuilder()

            // 3. 变形区 (如果有)
            if (this.currentParsedExchanges.length > 0) {
              this.exchangesBuilder()
            }

            // 4. 例句区
            if (this.currentParsedExamples.length > 0) {
              this.examplesBuilder()
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 30 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F7F2')
  }

  @Builder
  private headerBuilder() {
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
  private wordDisplayBuilder() {
    Column({ space: 8 }) {
      Text(this.wordData?.word.wordContent)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1B9680')

      if (this.wordData?.word.phoneticUs) {
        Text(`美 [${this.wordData.word.phoneticUs.replace(/\[|\]/g, '')}]`)
          .fontSize(16)
          .fontColor('#666')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  private meaningBuilder() {
    Column({ space: 10 }) {
      ForEach(this.getMeaningLines(this.wordData!.word), (line: string) => {
        Text(line)
          .fontSize(17)
          .lineHeight(26)
          .fontColor('#333')
          .width('100%')
      }, (line: string) => line)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0A000000', offsetY: 4 })
  }

  @Builder
  private exchangesBuilder() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.currentParsedExchanges, (exchange: ParsedExchange) => {
        Row({ space: 4 }) {
          Text(exchange.label).fontSize(13).fontColor('#888')
          Text(exchange.word).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#E8F5F2')
        .borderRadius(8)
        .margin({ right: 8, bottom: 8 })
      }, (item: ParsedExchange) => item.label + item.word)
    }
    .width('100%')
    .padding({ left: 4, right: 4 })
  }

  @Builder
  private examplesBuilder() {
    Column({ space: 15 }) {
      Text('例句')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .width('100%')
        .margin({ bottom: 5 })

      ForEach(this.currentParsedExamples, (item: ExampleSentence) => {
        Column({ space: 8 }) {
          // 英文部分高亮渲染
          Text() {
            ForEach(this.getHighlightedSegments(item.en, this.wordData?.word.wordContent || ''), (seg: TextSegment) => {
              Span(seg.text)
                .fontColor(seg.isHighlight ? '#1B9680' : '#333')
                .fontWeight(seg.isHighlight ? FontWeight.Bold : FontWeight.Normal)
            }, (seg: TextSegment) => seg.id)
          }
          .fontSize(16)
          .lineHeight(24)
          .width('100%')

          // 中文部分
          Text(item.zh)
            .fontSize(14)
            .fontColor('#666')
            .lineHeight(20)
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      }, (item: ExampleSentence) => item.id)
    }
    .width('100%')
  }
}