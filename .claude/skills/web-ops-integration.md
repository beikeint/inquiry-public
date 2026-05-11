---
name: web-ops-integration
description: 询盘智能体跟网站运营智能体的集成层 — 监听 GA4 generate_lead 事件 → 自动捕获询盘 → 5 分钟内触发首次响应 → 启动 email-nurture 7 天序列。修复 v9 之前的"询盘智能体设计完整但 0 触发"问题。
---

# inquiry × web-ops 集成层 v1.0

> **建立时间**：2026-04-27（v10.1 第二批：智能体协同）
> **解决的问题**：inquiry 智能体设计完整（6 skill / 4 MCP），但 30 天 0 触发，因为没人手动 feed 询盘进来
> **核心目标**：GA4 generate_lead 事件 → 5 分钟内自动触发首次响应（HBR 研究：1 小时内回复成功率 +7 倍）

---

## 一、数据流（完整链路）

```
访客在客户站点 WhatsApp / Form / Email / Phone CTA
       │
       ↓
GA4 触发 5 个转化事件之一：
  whatsapp_click / email_click / phone_click / quote_click / generate_lead
       │
       ↓
web-ops daily-cron 每小时拉取最新转化事件（v10.1 新增分支）
       │
       ↓
新询盘事件 → 写入 inquiry 智能体的 incoming-leads.jsonl
       │
       ↓
inquiry 智能体定时器检查（每 5 分钟）
       │
       ↓
触发 lead-capture skill：
  - 提取访客邮箱 / 公司 / 国家 / 询盘内容
  - 来源页面归因（哪个博客 / 产品页带来的）
  - 调 client-manager.add_client（如不存在）
  - 调 lead-enrichment（apollo MCP 充实信息）
       │
       ↓
触发 email-nurture skill 7 天序列：
  - Day 0（5 分钟内）：感谢 + 产品信息
  - Day 1：案例
  - Day 3：工厂介绍
  - Day 5：ROI 数据
  - Day 7：最后跟进
       │
       ↓
任意天买家回复 → 序列立即退出 → 通知运营人员/客户员工人工接管
       │
       ↓
deal-tracking skill 跟进到成交
       │
       ↓
成交事件 → 反哺 web-ops 写 case study（产品级目标）
```

---

## 二、技术接口（v10.1 落地版）

### A. web-ops 端：daily-cron.mjs 加询盘检查分支

**位置**：`mcp-servers/wecom-bot/daily-cron.mjs`

**新增行为**（每天必做段，不只是周三）：

```javascript
// v10.1 新增：每日询盘事件检查 + 转给 inquiry 智能体
【每日必做 7 · v10.1 新增】GA4 询盘事件捕获:
- 调 search-analytics MCP ga4_conversions 拿过去 24h 的 5 转化事件
- 对每个事件:
  - 访客 IP / UA / 邮箱（如填了 Form）/ 来源页面
  - 写入 ${WORKSPACE_ROOT}/智能体/运营/询盘-inquiry/incoming-leads/<日期>.jsonl
- 如发现新询盘 ≥ 1 条:
  - 立刻在简报"今日新询盘"段标红
  - 触发 inquiry 智能体（webhook 或 cron 立刻跑）
- 如 5 分钟内未见 inquiry 响应记录:
  - 推企微 P0 告警（响应超时是钱在漏）
```

### B. inquiry 端：incoming-leads/ 监听器

**位置**：新建 `智能体/运营/询盘-inquiry/incoming-leads/`

**目录结构**：
```
incoming-leads/
├── 2026-04-27.jsonl    ← 当日新询盘
├── 2026-04-26.jsonl    ← 历史
└── processed/           ← 已处理归档
```

**JSONL 格式**（每行一个询盘事件）：
```json
{
  "timestamp": "2026-04-27T08:30:15+08:00",
  "client_id": "client-D",
  "client_domain": "demo-b.com",
  "event_type": "generate_lead",
  "source_page": "/en/blog/pva-glue-vs-epoxy/",
  "visitor": {
    "email": "buyer@example.com",
    "country": "DE",
    "ip_geo": "Berlin, Germany"
  },
  "form_data": {
    "name": "Hans Mueller",
    "company": "Mueller Industries",
    "message": "Need 10 tons PVA glue, lead time?"
  },
  "ga4_data": {
    "session_id": "...",
    "first_visit_source": "google",
    "first_visit_medium": "organic"
  }
}
```

### C. inquiry cron（每 5 分钟检查 incoming-leads）

**新建**：`mcp-servers/wecom-bot/inquiry-cron.mjs`（仿 daily-cron）

或者**简单版**：加进现有 daily-cron 的"每日必做"段，调用 inquiry 智能体处理 incoming-leads/<今日>.jsonl

---

## 三、5 分钟响应硬规则（已有 inquiry 0.1 写过，重申）

**强制响应时长**：
- 询盘事件触发到首次响应邮件发出 ≤ **5 分钟**
- 如客户没填邮箱（只点了 WhatsApp / Phone）→ 推送企微 P0 告警让人工接管
- 数据来源：HBR 研究 — 1 小时内回复成功率比 24h 高 7 倍

**响应链路**：
```
0:00  GA4 generate_lead 触发
0:30  daily-cron / 实时 webhook 拉到事件
1:00  写入 incoming-leads/<日期>.jsonl
1:30  inquiry cron 检测到新事件
2:00  lead-capture 提取信息 + client-manager 建/找客户档案
3:00  lead-enrichment 充实（apollo MCP 查公司）
4:00  email-nurture Day 0 邮件草稿（按客户行业模板）
4:30  过 humanizer-zh 去 AI 味
5:00  email MCP 发出
```

---

## 四、归因闭环（数据反哺 web-ops）

每条询盘必须可追溯到：
- 来源页面（哪个博客 / 产品页带来）
- 来源关键词（GSC click 日志匹配）
- 客户旅程（GA4 sessionPath：进站到 generate_lead 的完整路径）

**反哺规则**：
- 每周日 inquiry 跑 weekly-pipeline skill 出"本周询盘 → 来源页面"统计
- 报告写入 `客户/<X>/website/docs/inquiry-attribution-<周>.md`
- web-ops 读这个报告 → 决定下周内容生产优先级（哪个主题真带询盘就多写）

---

## 五、错误处理

| 场景 | 动作 |
|---|---|
| GA4 API 限流（quota 耗尽） | 标记 incoming-leads 写入失败，下次 cron 重试 |
| 访客只点 WhatsApp 没填邮箱 | 写入 incoming-leads 但 visitor.email 为空，推企微让人工跟进 WhatsApp |
| inquiry email-nurture skill 跑失败 | 不影响 lead-capture（先建档案），重试 nurture，3 次失败推企微 |
| 重复询盘（同邮箱 24h 内多次） | 合并为 1 条，timeline 记录"重复询盘 Nx" |
| 客户站没装 GA4 转化事件 | daily-cron 简报红字告警"该客户站缺 GA4 5 事件" |

---

## 六、首次激活检查清单（每客户首次跑前）

- [ ] 客户站 GA4 5 转化事件全部部署（whatsapp/email/phone/quote/generate_lead）
- [ ] search-analytics MCP `ga4_conversions` 测试能拉到事件
- [ ] inquiry email MCP 配好 SMTP（客户公司邮箱 + 客户 contact 名）
- [ ] inquiry email-nurture 7 模板按客户行业调整（不同行业不同话术）
- [ ] client-manager 已建客户档案 + contact 信息
- [ ] daily-cron 已加询盘检查分支
- [ ] incoming-leads/ 目录可写
- [ ] 测试：用测试邮箱触发 generate_lead → 5 分钟内收到 Day 0 邮件 → 验证

---

## 七、监控

- **每天**：daily-cron 简报"今日新询盘 X 条 / 已响应 Y 条 / 响应平均时长 Z 分钟"
- **每周**：weekly-pipeline 报告
- **告警**：响应超时 ≥ 5 分钟 → 立刻推企微 P0
- **告警**：连续 7 天 0 询盘 → 推企微（不一定是问题，但提醒检查 GA4 事件是否正常）

---

## 八、成功指标（30 天验证）

- 5 分钟响应率 ≥ 95%
- nurture 序列完成率 ≥ 80%（5 天内被买家回复打断算成功）
- 询盘 → 报价转化率（30 天）：基线观察后定 KPI

---

*v10.1 第二批 · 智能体协同 · inquiry × web-ops 集成层 · 2026-04-27 立*
