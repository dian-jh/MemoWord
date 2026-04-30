// src/main/ets/mock/MockData.ets
import { StudyWord } from '../http/Api';

// 显式声明为 StudyWord[] 数组，满足 ArkTS 静态类型检查
export const mockWords: StudyWord[] = [
  {
    id: 101,
    wordContent: "algorithm",
    phoneticEn: "ˈælɡərɪðəm",   // 补齐必填项
    phoneticUs: "ˈælɡərɪðəm",
    definition: "n. a set of rules that must be followed...", // 补齐必填项
    translation: "n. 算法，运算法则",
    exampleSentences: "The page replacement algorithm is crucial for OS.<br>页面置换算法对操作系统至关重要。<br>This algorithm is much faster.<br>这个算法快得多。"
  },
  {
    id: 102,
    wordContent: "architecture",
    phoneticEn: "ˈɑːrkɪtektʃər",
    phoneticUs: "ˈɑːrkɪtektʃər",
    definition: "n. the art and study of designing buildings",
    translation: "n. 建筑学；架构",
    exampleSentences: "The software architecture is based on DDD.<br>该软件架构基于领域驱动设计。<br>He studied architecture at university.<br>他在大学里学习建筑学。"
  },
  {
    id: 103,
    wordContent: "mechanism",
    phoneticEn: "ˈmekənɪzəm",
    phoneticUs: "ˈmekənɪzəm",
    definition: "n. a set of moving parts in a machine",
    translation: "n. 机制；原理",
    exampleSentences: "The congestion control mechanism of TCP is very complex.<br>TCP的拥塞控制机制非常复杂。<br>We need to establish a feedback mechanism.<br>我们需要建立一个反馈机制。"
  },
  {
    id: 104,
    wordContent: "concurrent",
    phoneticEn: "kənˈkɜːrənt",
    phoneticUs: "kənˈkɜːrənt",
    definition: "adj. existing or happening at the same time",
    translation: "adj. 并发的；同时发生的",
    exampleSentences: "The system handles thousands of concurrent users.<br>该系统处理数千个并发用户。<br>Concurrent programming is highly demanding.<br>并发编程的要求非常高。"
  },
  {
    id: 105,
    wordContent: "compile",
    phoneticEn: "kəmˈpaɪl",
    phoneticUs: "kəmˈpaɪl",
    definition: "v. to translate instructions from one computer language",
    translation: "vt. 编译；汇编",
    exampleSentences: "The program takes a long time to compile.<br>该程序需要很长时间才能编译完成。<br>He compiled a dictionary of new words.<br>他编纂了一部新词典。"
  }
];