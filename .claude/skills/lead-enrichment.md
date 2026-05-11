---
name: lead-enrichment
description: 线索充实 — Apollo查询公司规模/行业/决策人/联系方式→Fetch验证公司官网→更新线索画像→调整评分和温度。让每条线索从"一个邮箱"变成"一个完整的客户画像"。
---

# 线索充实

> 触发指令：`充实 [线索/公司名]` / 在 lead-capture 中自动触发  
> 执行频率：每条新 Hot/Warm 线索必做，Cool 线索批量做  
> 人工确认：无需确认  
> 耗时：单条约1分钟（Apollo API调用）

---

## 执行流程

### Step 1: 提取已知信息

```
从 lead-capture 获取：
├─ 邮箱域名 → 推断公司域名（如 john@abcmachinery.com → abcmachinery.com）
├─ 联系人姓名（如表单中有）
├─ 来源页面 → 推断感兴趣的产品
└─ IP地理位置（如GA4有）→ 推断国家
```

### Step 2: Apollo 公司充实

```
并行执行：
├→ apollo.apollo_enrich_company({
│     domain: "abcmachinery.com"
│   })
│   → 获取：公司规模/行业/年营收/地理位置/技术栈
│
└→ apollo.apollo_search_people({
      organization_domains: ["abcmachinery.com"],
      person_titles: ["CEO", "Owner", "Purchasing Manager", "Procurement", "Import Manager"]
   })
   → 获取：决策人姓名/职位/邮箱/LinkedIn
```

### Step 3: Fetch 交叉验证

```
fetch(公司官网)
→ 验证：公司是否真实存在、主营业务是否匹配、规模是否对得上
→ 提取：产品线/客户案例/新闻动态（辅助后续个性化跟进）
```

**为什么要交叉验证：**
- Apollo数据可能过时（公司已倒闭/改行）
- 避免在虚假公司上浪费培育资源
- 竞品员工可能用个人邮箱询价

### Step 4: 更新线索画像

```
线索画像 = {
  // 基础信息
  contact_name: "John Smith",
  contact_email: "john@abcmachinery.com",
  contact_phone: "+1-xxx-xxx-xxxx",
  contact_linkedin: "linkedin.com/in/johnsmith",
  
  // 公司信息（Apollo）
  company_name: "ABC Machinery Co., Ltd",
  company_domain: "abcmachinery.com",
  company_size: "50-200",           // 评分加分项
  company_industry: "Packaging Equipment",
  company_location: "Turkey",
  company_revenue: "$5M-$10M",
  
  // 决策链（Apollo）
  decision_maker: "John Smith — CEO",
  other_contacts: ["procurement@abcmachinery.com — Purchasing Dept"],
  
  // 需求推断
  interested_product: "EPS Block Molding Machine",  // 从来源页面推断
  estimated_budget: "$30,000-$80,000",              // 从产品类型推断
  buying_stage: "Research",                          // 从行为推断
  
  // 评分调整
  score_before: 55,
  score_adjustment: "+10（公司规模>50）+10（目标市场匹配）",
  score_after: 75,
  temperature: "🔴 Hot → 🔴 Hot（更热了）"
}
```

### Step 5: 记录到 client-manager

```
client-manager.add_timeline(client_id, {
  date: "2026-04-14",
  event: "线索充实完成：{contact_name} @ {company_name}({country}) | 
          {company_size}人/{industry} | 决策人:{decision_maker} | 
          评分:{score_before}→{score_after} | 温度:{temperature}"
})
```

---

## 输出格式

```
## 线索充实报告 — John Smith

| 维度 | 信息 |
|------|------|
| 联系人 | John Smith — CEO |
| 公司 | ABC Machinery Co., Ltd (Turkey) |
| 规模 | 50-200人 / $5M-$10M营收 |
| 行业 | Packaging Equipment |
| 官网 | abcmachinery.com ✅ 已验证，主营包装设备 |
| 感兴趣 | EPS Block Molding Machine |
| 预算估计 | $30,000-$80,000 |
| 购买阶段 | Research（正在调研） |
| 评分 | 55 → 75（🔴 Hot） |
| 其他决策人 | procurement@abcmachinery.com |

**跟进建议**：高价值线索，建议运营人员24h内WhatsApp直联，针对Turkey市场准备案例。
```

---

## 批量充实模式

当积累了5+条未充实的Cool线索时，批量执行：

```
apollo.apollo_bulk_enrich_organizations({
  domains: ["company1.com", "company2.com", ...]
})

apollo.apollo_bulk_enrich_people({
  details: [
    {email: "contact1@company1.com"},
    {email: "contact2@company2.com"},
    ...
  ]
})
```

批量模式省API调用次数，适合Cool线索（不紧急）。

---

## 注意事项

- **Apollo API 有配额**：免费版每月有限，优先给 Hot 线索用
- **个人邮箱（gmail/hotmail/yahoo）无法 enrich 公司**：这种情况跳过公司充实，直接用 fetch 搜公司名
- **隐私合规**：Apollo 数据仅用于 B2B 商业联系，不用于个人营销
- **竞品识别**：如果 Apollo 显示公司行业是 "EPS Machinery Manufacturing"，可能是竞品，标记并报告
