---
name: email-nurture
description: 邮件培育序列 — 7天标准B2B外贸培育流（Day0感谢→Day1案例→Day3工厂→Day5 ROI→Day7最后跟进）。含模板管理、发送节奏、打开/点击追踪、序列退出规则。买家回复立即退出序列转人工。
---

# 邮件培育序列

> 触发指令：`[客户] 启动培育 [线索邮箱]` / `跟进 [线索]` / lead-capture 自动触发  
> 执行频率：新线索自动进入，按天触发  
> 人工确认：序列自动执行，买家回复时通知运营人员  
> 耗时：初始设置约5分钟/客户，之后全自动

---

## 一、培育序列模板

### 标准7天B2B外贸序列

**Day 0 — 即时感谢+产品信息（询盘后5分钟内）**

```
Subject: Thanks for your inquiry — {product_name} pricing & specs inside
From: {client_contact_name} <{client_email}>

Hi {first_name},

Thank you for your interest in our {product_name}. 

{company_cn_en} has been manufacturing {product_category} for {years} years, 
serving clients in {buyer_region} and 40+ countries worldwide.

Here's what you asked about:
- Product: {product_name}
- Key specs: {key_specs_2_lines}
- MOQ: {moq}
- Lead time: {lead_time}

📎 Attached: {product_name} full specification sheet

What's your target output capacity? I'll prepare a customized proposal for you.

Best regards,
{client_contact_name}
{client_company}
WhatsApp: {whatsapp_link}
```

**Day 1 — 成功案例（+1天）**

```
Subject: How {similar_country} client saved 30% with our {product_category}
From: {client_contact_name} <{client_email}>

Hi {first_name},

I wanted to share a recent success story that might be relevant:

📍 Client: {case_country} packaging manufacturer
📦 Product: {case_product}  
📊 Result: {case_result — e.g., "30% cost reduction, ROI in 8 months"}

{2-3 sentences about the case, with specific numbers}

[Photo: factory/installation/product]

Would you like to see more cases from {buyer_region}? Or shall we jump 
straight to discussing your specific requirements?

Best regards,
{signature}
```

**Day 3 — 工厂实力（+3天）**

```
Subject: Inside our factory — see where your {product_name} will be built
From: {client_contact_name} <{client_email}>

Hi {first_name},

I thought you might like to see where the magic happens:

🏭 Factory: {factory_size} sqm, {city}, China
👷 Team: {team_size}+ engineers and technicians
✅ Certifications: {certs — CE/ISO/etc}
📦 Annual output: {annual_output}

[2-3 factory photos or video link]

We also offer:
- Free video call factory tour
- Pre-shipment inspection
- {other_value_prop}

Want to schedule a video tour this week?

Best regards,
{signature}
```

**Day 5 — ROI分析（+5天）**

```
Subject: Your ROI projection for {product_name} — {X} months payback
From: {client_contact_name} <{client_email}>

Hi {first_name},

Based on typical {buyer_region} market conditions, here's a rough ROI 
projection for our {product_name}:

Investment: ${price_range}
Monthly output: {output} units
Revenue per unit: ${revenue_unit} (average for {buyer_region})
Monthly profit: ${monthly_profit}
Payback period: {months} months

👉 Want a projection customized to YOUR numbers? 
   Try our ROI calculator: {roi_calculator_url}

Or just reply with:
- Your target daily/monthly output
- Your local selling price per unit

I'll send you a detailed analysis within 24 hours.

Best regards,
{signature}
```

**Day 7 — 最后跟进（+7天）**

```
Subject: Quick question, {first_name}
From: {client_contact_name} <{client_email}>

Hi {first_name},

I noticed you were researching {product_category} last week. Are you still 
evaluating options?

If you're still in the decision process, I'm happy to:
✅ Answer any technical questions
✅ Arrange a video call with our engineer  
✅ Send you a competitive comparison chart
✅ Provide references from {buyer_region} clients

Just hit reply — I'll get back to you within 2 hours.

If the timing isn't right, no worries at all. I'll check back in a month.

Best regards,
{signature}
```

---

## 二、序列执行规则

### 发送条件

```
每天检查待发送队列：
├─ 当天是否有需要发送的序列邮件？
├─ 买家时区是否在工作时间？（周一至周五 9:00-17:00）
├─ 该线索是否已退出序列？
└─ 邮件内容是否已个性化？（禁止发模板原文）
```

### 退出条件（任一触发即退出）

| 条件 | 处理 |
|------|------|
| 买家回复了任何一封邮件 | **立即退出** → 通知运营人员人工跟进 |
| 买家点击了WhatsApp链接 | **立即退出** → 通知运营人员 |
| 买家明确说"不感兴趣" | **立即退出** → 标记Dead |
| 邮件连续退信（bounce） | **立即退出** → 标记无效联系 |
| 7天序列全部完成 | 正常退出 → 进入月度newsletter |
| 运营人员手动标记"已接管" | **立即退出** |

### MCP 调用链

```
检查是否需要发送：
  → email.list-logs({limit: 50})                    // 查看最近发送记录
  → 确认该线索上次发送时间，计算是否到了下一封

发送邮件：
  → email.send-email({
       to: 线索邮箱,
       from: 客户邮箱,
       subject: 个性化主题,
       html: 个性化内容
     })

追踪打开/点击：
  → email.list-logs({email: 线索邮箱})              // 查看打开/点击记录
  → 更新线索评分（打开+5，点击链接+10）

记录：
  → client-manager.add_timeline(client_id, {
       event: "培育序列Day{N}已发送给{contact} | 主题：{subject}"
     })
```

---

## 三、个性化规则

**每封邮件必须个性化以下字段：**
- `{first_name}` — 买家姓名
- `{product_name}` — 具体产品（从来源页面推断）
- `{buyer_region}` — 买家国家/地区
- `{similar_country}` — 选择与买家同地区的案例
- `{price_range}` — 产品价格范围
- `{key_specs}` — 产品核心规格

**禁止**：
- 发送未替换变量的模板（出现`{xxx}`原文 = 严重事故）
- 对同一线索一天发2封以上邮件
- 在邮件中承诺具体价格（只能给范围）
- 使用夸张营销语言（"BEST PRICE!!!" 等）

---

## 四、效果追踪

每周汇总培育数据：

```
## 本周邮件培育数据 — Demo-C

| 指标 | 数值 | 基准 |
|------|------|------|
| 发送量 | 12封 | - |
| 打开率 | 58% (7/12) | 行业均值35% |
| 点击率 | 25% (3/12) | 行业均值5% |
| 回复率 | 17% (2/12) | 行业均值3% |
| 退订率 | 0% | <1%正常 |
| 退信率 | 8% (1/12) | <5%正常 |

表现：✅ 打开率和回复率远超行业均值
建议：Day 5 ROI邮件点击率最高，可考虑提前到Day 3
```

---

## 五、注意事项

- **不是垃圾邮件**：这是对已主动联系我们的买家的跟进，不是cold email
- **CAN-SPAM合规**：每封邮件必须有退订链接（email MCP自带）
- **邮件发送频率**：同一线索每周最多3封（Day0+Day1+Day3 或 Day5+Day7）
- **模板要持续优化**：每月根据打开率/回复率数据调整主题和内容
- **案例和工厂照片需要客户提供**：如果还没有，先用行业通用内容替代，标记TODO
