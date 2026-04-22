@Observed
export class StudyStatistics {
  id: string;             // 主键 UUID
  userId: string;         // 用户ID
  statDate: string;       // 统计日期 (YYYY-MM-DD)
  learnedCount: number;   // 已背单词数
  targetCount: number;    // 目标数
  studyDuration: number;  // 学习时长（分钟）

  constructor(
    id: string,
    userId: string,
    statDate: string,
    learnedCount: number = 0,
    targetCount: number = 100,
    studyDuration: number = 0
  ) {
    this.id = id;
    this.userId = userId;
    this.statDate = statDate;
    this.learnedCount = learnedCount;
    this.targetCount = targetCount;
    this.studyDuration = studyDuration;
  }
}