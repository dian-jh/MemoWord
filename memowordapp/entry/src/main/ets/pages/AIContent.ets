import {
  getAiMessages,
  sendAiMessage,
  AiChatMessage,
  SendMessageData
} from '../http/Api';
import promptAction from '@ohos.promptAction';

@Component
export struct AIContent {
  // 显式指定消息数组类型
  @State messages: AiChatMessage[] = [];
  @State inputContent: string = "";
  @State isLoading: boolean = false;
  @State isRefreshing: boolean = false;

  // 严谨起见，sessionId 建议设为不可变或从父组件传入
  private sessionId: string = "1";
  private listScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 初始加载最近 20 条记录
    this.loadHistory(20);
  }

  /**
   * 严谨的加载历史记录逻辑
   */
  async loadHistory(take: number): Promise<void> {
    try {
      this.isRefreshing = true;
      const history: AiChatMessage[] = await getAiMessages(this.sessionId, take);

      // 这里的逻辑可以根据业务调整：是覆盖还是追加
      // 作为翻译模块，初次进入通常是覆盖显示最新记录
      this.messages = history;

      // 数据加载完成后，延迟滚动到底部，确保 List 已经完成渲染
      setTimeout(() => {
        this.listScroller.scrollEdge(Edge.Bottom);
      }, 200);

    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: error.message || "加载历史失败" });
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * 发送消息处理
   */
  async handleSend(): Promise<void> {
    const text: string = this.inputContent.trim();
    if (text.length === 0 || this.isLoading) {
      return;
    }

    this.isLoading = true;
    this.inputContent = ""; // 发送后立即清空输入框，提升用户交互体验

    try {
      // 调用在 Api.ets 中重构后的函数
      const result: SendMessageData = await sendAiMessage(this.sessionId, text);

      // 严谨追加消息：先加用户消息，再加回复消息
      this.messages.push(result.userMessage);
      this.messages.push(result.assistantMessage);

      // 自动滚动到最新消息
      this.listScroller.scrollEdge(Edge.Bottom);

    } catch (err) {
      const error = err as Error;
      promptAction.showToast({ message: error.message || "AI 响应超时，请重试" });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 1. 聊天记录区域 - 使用 Refresh 组件包裹 List 实现下拉刷新
      Refresh({ refreshing: $$this.isRefreshing }) {
        List({ scroller: this.listScroller, space: 12 }) {
          ForEach(this.messages, (item: AiChatMessage) => {
            ListItem() {
              this.MessageBubble(item)
            }
          }, (item: AiChatMessage) => item.id) // 使用消息 ID 作为 Key，提高渲染性能
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .edgeEffect(EdgeEffect.Spring) // 设置回弹效果
      }
      .onRefreshing(() => {
        // 下拉时拉取更多历史记录（例如 100 条）
        this.loadHistory(100);
      })

      // 2. 输入框区域
      Row() {
        TextInput({ text: this.inputContent, placeholder: '输入内容，AI 助手为你翻译...' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.White)
          .enterKeyType(EnterKeyType.Send) // 手机键盘显示“发送”键
          .onChange((value: string) => {
            this.inputContent = value;
          })
          .onSubmit(() => {
            this.handleSend();
          })

        Button() {
          if (this.isLoading) {
            LoadingProgress().width(20).height(20).color(Color.White)
          } else {
            Text("发送").fontColor(Color.White).fontSize(14)
          }
        }
        .margin({ left: 8 })
        .width(60)
        .height(40)
        .onClick(() => {
          this.handleSend();
        })
        .enabled(!this.isLoading)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F1F3F5') // 浅灰色背景区分输入区
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 消息气泡子组件
   * 根据 role 区分左右对齐和颜色
   */
  @Builder
  MessageBubble(msg: AiChatMessage) {
    Row() {
      if (msg.role === 'user') {
        Blank() // 推挤到右侧
        Text(msg.content)
          .padding(12)
          .backgroundColor('#007DFF') // 蓝色代表用户
          .fontColor(Color.White)
          .fontSize(15)
          .borderRadius({ topLeft: 15, bottomLeft: 15, bottomRight: 15 })
          .constraintSize({ maxWidth: '75%' }) // 限制气泡最大宽度
      } else {
        Text(msg.content)
          .padding(12)
          .backgroundColor(Color.White) // 白色代表 AI
          .fontColor(Color.Black)
          .fontSize(15)
          .borderRadius({ topRight: 15, bottomLeft: 15, bottomRight: 15 })
          .borderWidth(0.5)
          .borderColor('#E1E1E1')
          .constraintSize({ maxWidth: '75%' })
        Blank() // 推挤到左侧
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Bottom)
  }
}