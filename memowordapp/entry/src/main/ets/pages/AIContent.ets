import {
  getAiMessages,
  sendAiMessage,
  AiChatMessage,
  AiStructuredContent,
  AiCoreWord
} from '../http/Api';
import { promptAction, router } from '@kit.ArkUI';

// ======================== 1. 核心算法 ========================

interface HighlightToken {
  text: string;
  isTarget: boolean;
  wordId?: number;
}

// 强制要求 coreWords 传入严格的 AiCoreWord 数组或 undefined
// 强制要求入参兼容 (string | AiCoreWord)[]
function buildHighlightTokens(text: string, rawCoreWords: (string | AiCoreWord)[] | undefined): HighlightToken[] {
  if (!text) return [];
  if (!rawCoreWords || rawCoreWords.length === 0) {
    return [{ text: text, isTarget: false }];
  }

  // ✅ 核心修复：类型清洗 (Type Narrowing)
  // 将可能混杂着纯字符串和对象的数组，统一转换为强类型的 AiCoreWord 数组
  const coreWords: AiCoreWord[] = rawCoreWords.map((w: string | AiCoreWord) => {
    if (typeof w === 'string') {
      return { word: w, id: undefined } as AiCoreWord; // 旧数据没有ID
    }
    return w as AiCoreWord; // 新数据直接断言
  });

  const escapedWords = coreWords.map((w: AiCoreWord) => w.word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  const pattern = escapedWords.join('|');
  const regex = new RegExp(`\\b(${pattern})\\b`, 'gi');

  const parts = text.split(regex);
  const tokens: HighlightToken[] = [];

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    if (!part) continue;

    const matchedWord = coreWords.find((w: AiCoreWord) => w.word.toLowerCase() === part.toLowerCase());

    if (matchedWord) {
      tokens.push({ text: part, isTarget: true, wordId: matchedWord.id });
    } else {
      tokens.push({ text: part, isTarget: false });
    }
  }

  return tokens;
}
interface AiExpert {
  key: string;
  name: string;
  desc: string;
}

// ======================== 2. 核心组件 UI ========================

@Component
export struct AIContent {
  @State messages: AiChatMessage[] = [];
  @State inputContent: string = "";
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;
  @State isBooting: boolean = true;

  @State currentExpertKey: string = "TRANSLATOR";

  private experts: AiExpert[] = [
    { key: 'TRANSLATOR', name: '极简翻译', desc: '纯粹的翻译，地道语境表达' },
    { key: 'GRAMMAR_EXPERT', name: '语法剖析', desc: '像外科医生一样拆解句子成分' },
    { key: 'VOCAB_COACH', name: '词汇扩展', desc: '同义词对比与高频搭配讲解' },
    { key: 'WRITING_POLISHER', name: '作文润色', desc: '批判性纠错与高分表达替换' }
  ];

  private listScroller: Scroller = new Scroller();
  private historyTake: number = 20;

  aboutToAppear(): void {
    this.loadHistory(this.historyTake, true);
  }

  private canSend(): boolean {
    return this.inputContent.trim().length > 0 && !this.isLoading;
  }

  private scrollToBottom(delay: number = 0): void {
    if (delay > 0) {
      setTimeout(() => {
        this.listScroller.scrollEdge(Edge.Bottom);
      }, delay);
      return;
    }
    this.listScroller.scrollEdge(Edge.Bottom);
  }

  // ==================== 剥离出 Builder 的逻辑处理函数 ====================
  // 检查字符串是否是合法的 JSON (避免在 Builder 里面写 try-catch)
  private isJsonData(str: string): boolean {
    if (!str.startsWith('{')) return false;
    try {
      JSON.parse(str);
      return true;
    } catch (err) {
      return false;
    }
  }

  // 获取解析后的对象
  private getParsedData(str: string): AiStructuredContent {
    return JSON.parse(str) as AiStructuredContent;
  }

  private getExpertShortName(): string {
    const expert = this.experts.find((e: AiExpert) => e.key === this.currentExpertKey);
    return expert ? expert.name.substring(0, 1) : 'AI';
  }

  private async loadHistory(take: number, replace: boolean): Promise<void> {
    try {
      if (replace) this.isBooting = true;
      this.isRefreshing = true;
      const history: AiChatMessage[] = await getAiMessages(this.currentExpertKey, take);
      this.messages = history;
      this.scrollToBottom(180);
    } catch (err) {
      promptAction.showToast({ message: "加载历史失败" });
    } finally {
      this.isRefreshing = false;
      this.isBooting = false;
    }
  }

  private async handleSend(): Promise<void> {
    const text: string = this.inputContent.trim();
    if (text.length === 0 || this.isLoading) return;

    this.isLoading = true;
    const userText = text;
    this.inputContent = "";

    const tempUserMsg: AiChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: userText,
      createTime: new Date().toISOString()
    };
    this.messages = [...this.messages, tempUserMsg];
    this.scrollToBottom(50);

    try {
      const resultData: AiStructuredContent = await sendAiMessage(this.currentExpertKey, userText);

      const assistantMsg: AiChatMessage = {
        id: Date.now().toString(),
        role: 'assistant',
        content: JSON.stringify(resultData),
        createTime: new Date().toISOString()
      };

      this.messages = [...this.messages, assistantMsg];
      this.scrollToBottom(120);
    } catch (err) {
      promptAction.showToast({ message: "AI 响应超时，请重试" });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      this.headerBuilder()
      this.expertSelectorBuilder()

      if (this.isBooting && this.messages.length === 0) {
        this.loadingBuilder()
      } else {
        Refresh({ refreshing: $$this.isRefreshing }) {
          List({ scroller: this.listScroller, space: 16 }) {
            if (this.messages.length === 0) {
              ListItem() { this.emptyStateBuilder() }
            }

            ForEach(this.messages, (item: AiChatMessage) => {
              ListItem() { this.messageBubbleBuilder(item) }
            }, (item: AiChatMessage) => `${item.id}-${item.createTime}`)

            if (this.isLoading) {
              ListItem() { this.aiTypingBuilder() }
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 8, bottom: 12 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.historyTake = 100;
          this.loadHistory(this.historyTake, true);
        })
      }
      this.inputBuilder()
    }
    .width('100%').height('100%').backgroundColor('#F8F7F2')
  }

  // ============== UI Builder 区域 ==============

  @Builder
  private headerBuilder() {
    Column({ space: 4 }) {
      Text('AI 英语私教')
        .fontSize(26).fontWeight(FontWeight.Bold).fontColor('#222222')
      Text(this.experts.find((e: AiExpert) => e.key === this.currentExpertKey)?.desc || '')
        .fontSize(13).fontColor('#777777')
    }
    .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 10 }).alignItems(HorizontalAlign.Start)
  }

  @Builder
  private expertSelectorBuilder() {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(this.experts, (expert: AiExpert) => {
          Text(expert.name)
            .fontSize(14)
            .fontWeight(this.currentExpertKey === expert.key ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentExpertKey === expert.key ? '#FFFFFF' : '#666666')
            .backgroundColor(this.currentExpertKey === expert.key ? '#1B9680' : '#E8E8E8')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(20)
            .onClick(() => {
              if (this.isLoading || this.currentExpertKey === expert.key) return;
              this.currentExpertKey = expert.key;
              this.messages = [];
              this.historyTake = 20;
              this.loadHistory(this.historyTake, true);
            })
        }, (expert: AiExpert) => expert.key)
      }
      .padding({ left: 16, right: 16, bottom: 10, top: 4 })
    }
    .width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
  }

  @Builder
  private inputBuilder() {
    Row({ space: 10 }) {
      TextInput({ text: this.inputContent, placeholder: '输入内容，按发送即可...' })
        .layoutWeight(1).height(46).backgroundColor('#F1F4F3').borderRadius(23)
        .padding({ left: 16, right: 16 }).fontSize(15).enterKeyType(EnterKeyType.Send)
        .onChange((v: string) => this.inputContent = v)
        .onSubmit(() => this.handleSend())

      Button() {
        if (this.isLoading) {
          LoadingProgress().width(18).height(18).color(Color.White)
        } else {
          // 修复点：移除了 ic_send，替换为纯文字按钮，保证不报错
          Text("发送").fontColor(Color.White).fontSize(15).fontWeight(FontWeight.Medium)
        }
      }
      .width(66).height(46).borderRadius(23)
      .backgroundColor(this.canSend() ? '#1FBE93' : '#A9CFC2')
      .enabled(this.canSend())
      .onClick(() => this.handleSend())
    }
    .width('100%').padding({ left: 12, right: 12, top: 10, bottom: 12 })
    .backgroundColor('#FFFFFF').borderRadius({ topLeft: 24, topRight: 24 })
    .shadow({ radius: 12, color: '#08000000', offsetX: 0, offsetY: -4 })
  }

  @Builder
  private messageBubbleBuilder(msg: AiChatMessage) {
    Row() {
      // 1. 头像区
      if (msg.role !== 'user') {
        Text(this.getExpertShortName())
          .fontSize(10).fontWeight(FontWeight.Bold).fontColor('#1B9680')
          .width(32).height(32).textAlign(TextAlign.Center).backgroundColor('#E4F3EE')
          .borderRadius(16).padding({ top: 8 }).margin({ right: 10 })
      }

      // 2. 气泡容器区：使用 layoutWeight 完美自适应，并添加边界留白
      Column() {
        if (msg.role === 'user') {
          Text(msg.content)
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .fontSize(16).lineHeight(24).fontColor(Color.White).backgroundColor('#1FBE93')
            .borderRadius({ topLeft: 18, topRight: 18, bottomLeft: 18, bottomRight: 4 })
            // 修复：强制英文长串换行
            .wordBreak(WordBreak.BREAK_WORD)
        } else {
          if (this.isJsonData(msg.content)) {
            this.structuredAiResponseBuilder(this.getParsedData(msg.content));
          } else {
            Text(msg.content)
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .fontSize(16).lineHeight(26).fontColor('#333')
              .backgroundColor('#FFFFFF')
              .borderRadius({ topLeft: 18, topRight: 18, bottomLeft: 4, bottomRight: 18 })
              .wordBreak(WordBreak.BREAK_WORD)
          }
        }
      }
      .layoutWeight(1) // ✅ 关键修复：让气泡占据剩余空间
      .alignItems(msg.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
      // ✅ 关键修复：用户消息左侧留白，AI 消息右侧留白，防止顶满屏幕
      .margin({
        left: msg.role === 'user' ? 40 : 0,
        right: msg.role !== 'user' ? 40 : 0
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ bottom: 4 }) // 增加气泡间距
  }

  @Builder
  private structuredAiResponseBuilder(data: AiStructuredContent) {
    Column({ space: 10 }) {
      if (data.translation) {

        // ✅ 直接调用辅助方法，ArkTS 编译器完美通过
        if (this.hasValidInteractiveWords(data.coreWords)) {
          // 🌟 场景一：新发送的消息，进行精准切分、高亮并绑定点击事件
          Text() {
            ForEach(buildHighlightTokens(data.translation, data.coreWords), (token: HighlightToken) => {
              Span(token.text)
                .fontColor(token.isTarget ? '#1B9680' : '#222222')
                .fontWeight(token.isTarget ? FontWeight.Bold : FontWeight.Normal)
                .decoration({
                  type: token.isTarget ? TextDecorationType.Underline : TextDecorationType.None,
                  color: '#1B9680'
                })
                .onClick(() => {
                  if (token.isTarget && token.wordId !== undefined) {
                    router.pushUrl({
                      url: 'pages/WordDetailPage',
                      params: { wordId: token.wordId }
                    });
                  }
                })
            }, (token: HighlightToken, index: number) => index.toString())
          }
          .fontSize(16).lineHeight(26).width('100%')
        } else {
          // 📜 场景二：历史查询数据，直接渲染原文
          Text(data.translation)
            .fontSize(16)
            .lineHeight(26)
            .fontColor('#222222')
            .width('100%')
        }
      }

      if (data.analysis) {
        if (data.translation) Divider().color('#F0F0F0').strokeWidth(1)

        ForEach(data.analysis.replace(/\\n/g, '\n').split('\n'), (line: string) => {
          if (line.trim().length > 0) {
            Text(line)
              .fontSize(15)
              .lineHeight(24)
              .fontColor('#555555')
              .width('100%')
              .wordBreak(WordBreak.BREAK_WORD)
          }
        }, (line: string, index: number) => index.toString())
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 18, topRight: 18, bottomLeft: 4, bottomRight: 18 })
    .shadow({ radius: 8, color: '#08000000', offsetY: 3 })
    .alignItems(HorizontalAlign.Start)
  }

  private hasValidInteractiveWords(coreWords?: (string | AiCoreWord)[]): boolean {
    if (!coreWords || coreWords.length === 0) return false;
    return coreWords.some((w: string | AiCoreWord) => typeof w === 'object' && w.id !== undefined);
  }

  @Builder
  private loadingBuilder() {
    Column({ space: 12 }) {
      LoadingProgress().width(34).height(34).color('#1FBE93')
      Text('正在加载会话...').fontSize(14).fontColor('#666666')
    }
    .layoutWeight(1).justifyContent(FlexAlign.Center).width('100%')
  }

  @Builder
  private emptyStateBuilder() {
    Column({ space: 10 }) {
      Text('我是你的专属专家').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#333333')
      Text('随时向我提问吧').fontSize(14).fontColor('#888888')
    }
    .width('100%').padding({ top: 40, bottom: 18 }).alignItems(HorizontalAlign.Center)
  }

  @Builder
  private aiTypingBuilder() {
    Row() {
      Text(this.getExpertShortName())
        .fontSize(10).fontWeight(FontWeight.Bold).fontColor('#1B9680')
        .width(32).height(32).textAlign(TextAlign.Center).backgroundColor('#E4F3EE')
        .borderRadius(16).padding({ top: 8 }).margin({ right: 10 })

      Column() {
        Row({ space: 8 }) {
          LoadingProgress().width(16).height(16).color('#1B9680')
          Text('专家正在思考...').fontSize(13).fontColor('#666666')
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 18, topRight: 18, bottomLeft: 4, bottomRight: 18 })
        .shadow({ radius: 8, color: '#08000000', offsetY: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ right: 40 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}