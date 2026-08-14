/// 本地敏感词过滤（公安安全评估「内容审核机制」的代码实据）
///
/// 聊天发送前调用 [firstHit] 检查，命中则拦截并提示文明交流。
/// 词表为通用违规类别（黄赌毒诈 + 人身攻击），刻意避开易误伤日常用词，
/// 全部本地匹配、零网络依赖，符合"全匿名、小数据"的产品底线。
class SensitiveWords {
  SensitiveWords._();

  static const List<String> _words = [
    // 赌博
    '赌博', '博彩', '赌场', '六合彩', '时时彩', '百家乐', '下注',
    // 毒品
    '冰毒', '海洛因', '摇头丸', '毒品交易', '制毒',
    // 诈骗 / 违法交易
    '诈骗', '代开发票', '办理假证', '洗钱', '高利贷',
    // 色情
    '裸聊', '约炮', '援交', '招嫖', '卖淫', '色情交易',
    // 暴力 / 违法
    '枪支', '弹药', '炸弹', '杀人', '砍人', '恐怖袭击',
    // 人身攻击
    '傻逼', '去死', '废物', '垃圾人', '滚蛋',
  ];

  /// 返回命中的第一个敏感词；没有命中返回 null。
  static String? firstHit(String text) {
    for (final w in _words) {
      if (text.contains(w)) return w;
    }
    return null;
  }

  /// 是否包含敏感词。
  static bool hasSensitive(String text) => firstHit(text) != null;
}
