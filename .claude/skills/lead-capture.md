---
name: lead-capture
description: 询盘捕获与分级 — GA4事件解读→联系信息提取→Lead Scoring评分→温度分级（Hot/Warm/Cool）→自动首响应→写入client-manager时间线。每条询盘可追溯到来源页面和关键词。
---

# 询盘捕获与分级

> 触发指令：`今日询盘` / `[客户名] 查询盘`  
> 执行频率：每天至少一次（理想：实时）  
> 人工确认：无需确认。捕获+分级+首响应全自动  
> 耗时：全局模式约5分钟 / 单客户约2分钟

---

## 执行流程

### Step 1: 采集询盘数据

```
并行执行：
├→ client-manager.list_clients(active)         // 获取所有活跃客户
├→ 对每个客户：
│   ├→ search-analytics.ga4_conversions(        // 拉GA4转化事件
│   │     property_id, days=1)
│   └→ search-analytics.ga4_traffic_sources(    // 来源渠道
│         property_id, days=1)
└→ email.list-received-emails()                 // 检查是否有表单提交邮件
```

### Step 2: 识别新询盘

**GA4事件 → 询盘类型映射：**

| GA4事件 | 询盘类型 | 基础分值 |
|---------|---------|---------|
| `generate_lead`（表单/弹窗） | 主动询盘 | +30 |
| `whatsapp_click` | WhatsApp咨询 | +25 |
| `phone_click` | 电话咨询 | +15 |
| `email_click` | 邮件咨询 | +15 |
| `quote_click` | 报价意向 | +10 |
| `roi_calculated` | 深度参与 | +20 |

**来源页面追溯：**
```
GA4事件 → page_location → 确定来源页面
来源页面 → GSC search_performance → 确定来源关键词
记录：{source_page, source_keyword, source_channel, timestamp}
```

### Step 3: Lead Scoring 评分

```
基础分（来自GA4事件类型）
  + 行为加分：
    ├─ 多次访问（3+次同一用户）   +10
    ├─ 浏览>3个页面              +5
    ├─ 访问了产品页+联系页        +10
    └─ 停留>3分钟               +5
  + 画像加分（如已有Apollo数据）：
    ├─ 公司规模>50人             +10
    ├─ 目标市场匹配              +10
    └─ 决策人角色                +15
```

### Step 4: 温度分级

```
总分 ≥ 50 → 🔴 Hot   → 触发：立即自动回复 + 通知运营人员人工跟进
总分 30-49 → 🟡 Warm  → 触发：24小时内邮件跟进
总分 10-29 → 🟢 Cool  → 触发：进入7天自动培育序列
总分 < 10  → 暂不处理，记录观察
```

### Step 5: 自动首响应

**Hot 线索首响应（5分钟内）：**
```
email.send-email({
  to: 线索邮箱,
  subject: "Thanks for your inquiry — {product} details inside",
  body: 个性化模板（含：公司简介+产品规格+WhatsApp链接+邀请回复）
})
```

**首响应邮件必须包含：**
- 买家公司名（如果能提取）
- 具体产品名称（从来源页面推断）
- 公司简介（1-2句）
- 下一步行动（WhatsApp/回复邮件/预约视频）

### Step 6: 记录到 client-manager

```
client-manager.add_timeline(client_id, {
  date: "2026-04-14",
  event: "新询盘：[Hot/Warm/Cool] | 来源：{source_page} | 关键词：{keyword} | 
          联系方式：{contact} | 评分：{score}分 | 已发送首响应邮件"
})
```

---

## 输出格式

```
## 今日询盘报告 — 2026-04-14

### Demo-C (demo-c.com)
| # | 时间 | 类型 | 来源页面 | 关键词 | 温度 | 评分 | 状态 |
|---|------|------|---------|--------|------|------|------|
| 1 | 09:15 | WhatsApp | /en/blog/eps-buying-guide/ | eps machine price | 🔴Hot | 55 | ✅已响应 |
| 2 | 14:30 | 表单提交 | /en/contact/ | china eps factory | 🔴Hot | 60 | ✅已响应+已通知运营人员 |
| 3 | 18:00 | email_click | /en/products/pre-expander/ | - | 🟢Cool | 15 | ✅进入培育序列 |

### Demo-D (demo-a.com)
无新询盘

---
今日合计：3条新询盘（2 Hot / 0 Warm / 1 Cool）
需要运营人员跟进：#1 #2（已WhatsApp通知）
```

---

## 注意事项

- **GA4数据可能有延迟**（最多24-48小时），所以每天检查的是"昨天"的事件
- **表单提交邮件是最可靠的信号**：同时检查 email.list-received-emails 和 GA4 事件，交叉验证
- **同一个用户的多个事件合并计分**：一个人既点了WhatsApp又提交了表单 = 累加分数，不是两条独立线索
- **已知联系人不重复建档**：如果邮箱/电话已在系统中，更新评分而非新建
