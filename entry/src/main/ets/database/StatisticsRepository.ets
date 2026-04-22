import relatioinalStore from '@ohos.data.relationalStore';
import { StudyStatistics } from '../model/StudyStatistics';

export class StatisticsRepository {
  static readonly TABLE_NAME = 'StudyStatistics';
  static readonly COL_ID = 'Id';
  static readonly COL_USER_ID = 'UserId';
  static readonly COL_DATE = 'StatDate';
  static readonly COL_LEARNED = 'LearnedCount';
  static readonly COL_TARGET = 'TargetCount';
  static readonly COL_DURATION = 'StudyDuration';

  private static resultSetToModel(resultSet: relatioinalStore.ResultSet): StudyStatistics {
    // 修复点 1: 将 this 替换为 StatisticsRepository
    // 修复点 2: 将 getInt 替换为 getLong
    return new StudyStatistics(
      resultSet.getString(resultSet.getColumnIndex(StatisticsRepository.COL_ID)),
      resultSet.getString(resultSet.getColumnIndex(StatisticsRepository.COL_USER_ID)),
      resultSet.getString(resultSet.getColumnIndex(StatisticsRepository.COL_DATE)),
      resultSet.getLong(resultSet.getColumnIndex(StatisticsRepository.COL_LEARNED)),
      resultSet.getLong(resultSet.getColumnIndex(StatisticsRepository.COL_TARGET)),
      resultSet.getLong(resultSet.getColumnIndex(StatisticsRepository.COL_DURATION))
    );
  }

  /**
   * 获取用户最近7天的统计数据 (示例补全)
   */
  async getWeeklyStatistics(store: relatioinalStore.RdbStore, userId: string): Promise<StudyStatistics[]> {
    let predicates = new relatioinalStore.RdbPredicates(StatisticsRepository.TABLE_NAME);
    predicates.equalTo(StatisticsRepository.COL_USER_ID, userId)
      .orderByAsc(StatisticsRepository.COL_DATE);

    let resultSet = await store.query(predicates);
    let statisticsList: StudyStatistics[] = [];

    while (resultSet.goToNextRow()) {
      statisticsList.push(StatisticsRepository.resultSetToModel(resultSet));
    }
    resultSet.close(); // 记得关闭结果集，释放内存
    return statisticsList;
  }
}