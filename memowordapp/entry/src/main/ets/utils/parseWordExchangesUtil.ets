// 定义一个给 UI 渲染使用的接口
export interface ParsedExchange {
  label: string; // 例如："复数"
  word: string;  // 例如："turnips"
}

// 建立映射字典
const EXCHANGE_DICT: Record<string, string> = {
  's': '复数',
  'p': '过去式',
  'd': '过去分词',
  'i': '现在分词',
  '3': '三单',
  'r': '比较级',
  't': '最高级',
  '0': '原型'
};

/**
 * 解析词性变化字符串
 * @param raw 从数据库拿到的原始字符串，如 "s:foregrounds/i:foregrounding/d:foregrounded"
 * @returns 格式化后的数组，可直接用于 ForEach 渲染
 */
export function parseWordExchanges(raw: string | null | undefined): ParsedExchange[] {
  if (!raw) {
    return [];
  }

  const results: ParsedExchange[] = [];
  // 1. 按照 '/' 切割成多个键值对
  const segments: string[] = raw.split('/');

  for (let segment of segments) {
    // 2. 按照 ':' 切割出 key 和 value
    const parts = segment.split(':');
    if (parts.length === 2) {
      const key = parts[0].trim();
      const value = parts[1].trim();

      // 3. 严谨性过滤：只处理我们在字典里定义过的已知前缀
      // 并且过滤掉 value 是单字母的脏数据（比如 "1:i"）
      if (EXCHANGE_DICT[key] !== undefined && value.length > 1) {
        results.push({
          label: EXCHANGE_DICT[key],
          word: value
        });
      }
    }
  }

  // 4. (进阶) 数据去重：有时候过去式和过去分词完全一样，比如 d:foregrounded / p:foregrounded
  // 如果你想让 UI 更清爽，可以做合并去重，这里为了保持简单直接返回
  return results;
}