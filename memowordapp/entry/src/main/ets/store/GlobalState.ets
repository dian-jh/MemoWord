// 定义全局存储的 Key 键名，避免字符串硬编码错误
export class StorageKeys {
  static readonly STATISTICS_LIST = 'statisticsList';
  static readonly TOTAL_GOAL = 'totalGoal';
  static readonly TODAY_LEARNED = 'todayLearned';
  static readonly TODAY_TIME = 'todayTime';
  static readonly IS_DATA_READY = 'isDataReady';
}

/**
 * 初始化全局状态
 * 在应用启动时（如 EntryAbility.ets）调用一次
 */
export function initGlobalState() {
  AppStorage.setOrCreate(StorageKeys.STATISTICS_LIST, []);
  AppStorage.setOrCreate(StorageKeys.TOTAL_GOAL, 0);
  AppStorage.setOrCreate(StorageKeys.TODAY_LEARNED, 0);
  AppStorage.setOrCreate(StorageKeys.TODAY_TIME, 0);
  AppStorage.setOrCreate(StorageKeys.IS_DATA_READY, false);
}