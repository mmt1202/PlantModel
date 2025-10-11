// /model/EmergencyPlaybook.ets
// 急救方案内置清单（纯内存常量；后续可替换为RDB/JSON载入）

export class PlayStep {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

export class PlaybookItem {
  key: string = '';          // 例如 SCORCH
  title: string = '';        // 例如 疑似日灼
  steps: Array<PlayStep> = new Array<PlayStep>(); // 三步卡
  reviewHours: number = 72;  // 建议复查间隔（小时）
  tip: string = '';          // 补充提示

  constructor(key: string, title: string, steps: Array<PlayStep>, reviewHours: number, tip: string) {
    this.key = key;
    this.title = title;
    this.steps = steps;
    this.reviewHours = reviewHours;
    this.tip = tip;
  }
}

export function getBuiltinPlaybook(): Array<PlaybookItem> {
  const list: Array<PlaybookItem> = new Array<PlaybookItem>();
  list.push(new PlaybookItem(
    'SCORCH',
    '疑似日灼',
    [ new PlayStep('立即移至散射光处，避免直射 ≥48 小时'),
      new PlayStep('剪除严重灼伤叶片的 30%~50%'),
      new PlayStep('减少浇水量，1 周后逐步恢复') ],
    72,
    '后续 1 周内增加通风，避免午后强光直射。'
  ));
  list.push(new PlaybookItem(
    'WILT',
    '急性萎蔫',
    [ new PlayStep('检查介质含水：干透则少量补水，湿重则停止浇水'),
      new PlayStep('移至阴凉处观察 24 小时'),
      new PlayStep('确认无根系损伤后逐步恢复原位') ],
    48,
    '避免短时大量浇水造成根系缺氧。'
  ));
  list.push(new PlaybookItem(
    'YELLOW',
    '黄化发黄',
    [ new PlayStep('检查光照：不足则增加 20%~30% 光照'),
      new PlayStep('薄肥勤施：稀释 1/2 普通叶肥'),
      new PlayStep('排查盆土长期过湿情况') ],
    96,
    '若新叶仍明显发黄，考虑缺铁或介质问题。'
  ));
  list.push(new PlaybookItem(
    'SPOT',
    '叶片黑斑/斑点',
    [ new PlayStep('剪除感染严重叶片，避免交叉污染'),
      new PlayStep('加强通风，保持叶面干燥'),
      new PlayStep('必要时使用常规园艺杀菌剂（按说明）') ],
    72,
    '处理后 72 小时观察是否继续扩散。'
  ));
  list.push(new PlaybookItem(
    'ROOTROT',
    '疑似烂根',
    [ new PlayStep('立即停水，移至通风阴凉'),
      new PlayStep('轻脱盆检查，剪除黑褐色腐烂根系'),
      new PlayStep('更换干净、透气新介质，少量补水定根') ],
    48,
    '后续两周严格控水，待新根恢复后再逐步增加水量。'
  ));
  return list;
}

export function findPlaybookByKey(list: Array<PlaybookItem>, key: string): PlaybookItem | undefined {
  for (let i: number = 0; i < list.length; i++) {
    if (list[i].key === key) { return list[i]; }
  }
  return undefined;
}
