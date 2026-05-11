---
name: deal-tracking
description: 成交追踪与内容归因 — 管理询盘→报价→谈判→成交/流失全阶段，每笔成交归因到来源内容/关键词/渠道，计算真实ROI。生成内容归因报告回传给网站运营-web-ops。
---

# 成交追踪与内容归因

> 触发指令：`[客户] 更新成交 [线索]` / `[客户] 询盘月报` / `内容归因报告`  
> 执行频率：线索状态变更时实时更新 + 每月汇总  
> 人工确认：成交金额需运营人员确认  
> 耗时：状态更新1分钟 / 月报15分钟

---

## 一、成交阶段管理

### 阶段定义与流转

```
New Lead → Contacted → Qualified → Quoted → Negotiating → Won/Lost/On Hold
   │          │           │          │          │
   5min       24h        1-3d       3-7d      7-30d
   自动        自动       人工+AI    人工       人工
```

### 阶段更新指令

```
更新 [线索] 到 [阶段]
  例：更新 john@abc.com 到 已报价 $45,000
  例：更新 Mehmet 到 已成交 $42,000
  例：更新 Ahmed 到 流失 原因:选了竞品fang-yuan
```

### 每次阶段变更必须记录

```
client-manager.add_timeline(client_id, {
  date: "2026-04-20",
  event: "询盘阶段变更：{contact_name}({company}) | {old_stage}→{new_stage} | 
          金额：${amount} | 备注：{note}"
})
```

---

## 二、归因模型

### 单笔成交归因链路

```
归因数据结构：
{
  // 线索信息
  "lead_id": "L-2026-04-001",
  "contact": "John Smith",
  "company": "ABC Machinery (Turkey)",
  
  // 来源归因
  "first_touch_channel": "organic_search",       // 首次触达渠道
  "first_touch_page": "/en/blog/eps-buying-guide/",  // 首次着陆页
  "first_touch_keyword": "eps machine price",    // 搜索关键词
  "first_touch_date": "2026-04-15",
  
  // 转化归因  
  "conversion_event": "generate_lead",           // 转化GA4事件
  "conversion_page": "/en/contact/",             // 转化页面
  "conversion_date": "2026-04-15",
  
  // 培育过程
  "nurture_emails_sent": 3,
  "nurture_emails_opened": 3,
  "nurture_emails_clicked": 2,
  "human_touchpoints": 4,                        // 运营人员手动跟进次数
  
  // 成交信息
  "deal_stage": "Won",
  "deal_amount": 42000,
  "deal_currency": "USD",
  "close_date": "2026-05-02",
  "days_to_close": 17,
  "lost_reason": null,                           // 流失原因（如果Lost）
  
  // 归因计算
  "attributed_content": "/en/blog/eps-buying-guide/",
  "attributed_keyword": "eps machine price",
  "content_roi": "该文章成本$50（AI生产+翻译），ROI = 840x"
}
```

### 流失归因（同样重要）

```
流失必须记录原因：
├─ 选了竞品（哪家？）→ 反馈给网站运营做竞品分析
├─ 价格太高 → 反馈给运营人员调整报价策略
├─ 需求变了 → 记录，30天后重新激活
├─ 无响应（ghost）→ 分析在哪个阶段丢失的
└─ 其他 → 具体原因

流失分析价值：
- 如果70%流失在"已报价"阶段 → 报价策略有问题
- 如果60%流失给同一个竞品 → 需要针对性竞争策略
- 如果"需求确认"到"已报价"转化率<30% → 需求理解不到位
```

---

## 三、月度询盘报告

### 执行流程

```
Step 1: 拉取本月所有时间线中含"询盘"的记录
        → client-manager.get_client(id) → 过滤时间线

Step 2: 分阶段统计
        → 新线索数 / 各阶段分布 / 转化率 / 成交额

Step 3: 内容归因汇总
        → 每篇内容带来的询盘数和成交额

Step 4: 生成报告
```

### 输出格式

```
## 4月询盘月报 — Demo-C

### 总览
| 指标 | 本月 | 上月 | 环比 |
|------|------|------|------|
| 新询盘 | 11 | 6 | +83% |
| 已响应 | 11/11 | 5/6 | 100% ✅ |
| 已报价 | 5 | 3 | +67% |
| 已成交 | 2 | 1 | +100% |
| 成交额 | $70,000 | $28,000 | +150% |
| 平均成交周期 | 14天 | 21天 | -33% |
| 流失 | 3 | 2 | - |

### 漏斗转化率
New(11) → Contacted(11) 100%
  → Qualified(8) 73%
    → Quoted(5) 63%
      → Won(2) 40%  |  Lost(3)  |  Negotiating(0)

### 内容归因
| 内容 | 询盘数 | 成交数 | 成交额 | 内容成本 | ROI |
|------|--------|--------|--------|---------|-----|
| EPS Buying Guide | 5 | 1 | $42,000 | ~$50 | 840x |
| ICF Production Guide | 3 | 0 | 培育中 | ~$50 | - |
| ROI Calculator | 2 | 1 | $28,000 | ~$30 | 933x |
| 直接访问 | 1 | 0 | - | - | - |

### 流失分析
| 线索 | 阶段 | 原因 | 建议 |
|------|------|------|------|
| Ahmed (Egypt) | Quoted | 选了fang-yuan，价格低15% | 需要强调售后和质量差异 |
| Pavel (Russia) | Qualified | 预算不够，明年再看 | 30天后重新跟进 |
| Kim (Vietnam) | Contacted | 无响应 | 已进入月度newsletter |

### 关键洞察
1. EPS Buying Guide 是最赚钱的页面，建议网站运营重点优化排名
2. 土耳其市场转化率最高（3询盘→1成交），值得加大投入
3. 报价到成交转化率40%，高于行业均值（25%），报价质量好
4. 最大流失原因是价格竞争（fang-yuan），需要差异化话术

### 回传给网站运营-web-ops
→ 最赚钱的内容：EPS Buying Guide ($42K) > ROI Calculator ($28K)
→ 最高价值关键词：eps machine price > icf block production
→ 内容建议：写更多 buying guide 类型的内容，转化率最高
```

---

## 四、内容归因报告（回传网站运营）

单独生成，专门给网站运营-web-ops使用：

```
client-manager.add_timeline(client_id, {
  date: "2026-04-30",
  event: "内容归因回传（4月）：
    #1 /en/blog/eps-buying-guide/ → 5询盘/1成交/$42,000
    #2 /en/roi-calculator/ → 2询盘/1成交/$28,000
    #3 /en/blog/icf-production-guide/ → 3询盘/0成交/培育中
    本月总营收 $70,000 | 网站带来的直接ROI: {X}倍"
})
```

**这条时间线记录是两个智能体的数据桥：**
- 网站运营-web-ops月报可以引用这个数据
- 网站运营的选题策略可以基于"哪篇内容最赚钱"来优化

---

## 五、注意事项

- **金额以运营人员确认为准**：AI只记录，不能编造成交金额
- **归因是"首次触达"模型**：一个客户可能看了5篇文章，但归因到他第一次进来的那篇
- **流失原因必须追问**：不能简单标记"流失"就完了，必须知道为什么
- **保密**：成交金额和客户信息不外传，仅内部使用
- **定期核对**：每月与运营人员核对一次，确认数据准确
