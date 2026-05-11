---
name: outbound-prospect
description: 轻量主动开发（快速试探） — 用Apollo快速搜索一批目标客户→生成名单→交给获客智能体深度执行。本技能只做"找人+出名单"，不做深度触达序列（那是邮件开发/LinkedIn开发-linkedin-outreach的活）。
---

# 轻量主动开发（快速试探）

> 触发指令：`主动开发 [行业/地区]` / `[客户] 找客户 [条件]`  
> 执行频率：每双周一次，或客户要求时  
> 人工确认：⏸️ 名单确认后决定执行方式  
> 耗时：调研+出名单约15分钟

---

## 定位说明：与获客智能体的分工

```
本技能（轻量试探）               获客智能体（深度执行）
━━━━━━━━━━━━━━━━              ━━━━━━━━━━━━━━━━━━
Apollo搜索 → 出名单              邮件开发-email-outreach：域名预热+EQS评分+送达率优化+完整序列
快速判断市场是否值得投入           LinkedIn开发-linkedin-outreach：连接策略+内容发布+LQS评分+消息序列
                                 询盘回复-inquiry-reply：收到回复后的专业处理+BIS评分+生命周期管理

执行路径：
  本技能出名单 → ⏸️ 运营人员确认
    → 简单试探（≤5家）→ 本技能直接发一封试探邮件
    → 深度开发（>5家）→ 移交给获客/邮件开发-email-outreach执行完整序列
```

**原则：不重复造轮子。** 获客目录下的邮件开发-email-outreach有完整的EQS评分、域名预热、送达率优化体系；LinkedIn开发-linkedin-outreach有LQS评分、内容策略、连接优化。本技能不复制这些能力，只做上游的"找人+初筛"。

---

## 执行流程

### Phase 1: 目标定义（与运营人员确认）

```
需要明确：
├─ 目标行业：如 "Packaging / Construction / Insulation"
├─ 目标地区：如 "Turkey, Egypt, Saudi Arabia"
├─ 目标规模：如 "50-500人"
├─ 目标角色：如 "CEO / Purchasing Manager / Plant Manager"
├─ 排除条件：如 "排除中国公司 / 排除竞品"
└─ 本次数量：建议每次10-20家（精准>数量）
```

### Phase 2: Apollo 搜索

```
apollo.apollo_search_companies({
  organization_industry_tag_ids: ["packaging"],
  organization_locations: ["Turkey", "Egypt", "Saudi Arabia"],
  organization_num_employees_ranges: ["51,200"],
  per_page: 25
})

→ 得到公司列表后，对每家公司：

apollo.apollo_search_people({
  organization_domains: [公司域名],
  person_titles: ["CEO", "Owner", "Managing Director", "Purchasing Manager", "Plant Manager"],
  per_page: 5
})

→ 得到决策人列表
```

### Phase 3: 名单整理 → ⏸️ 确认

输出格式：

```
## 主动开发名单 — EPS设备 × 土耳其市场

| # | 公司 | 规模 | 行业 | 决策人 | 职位 | 邮箱 | LinkedIn | 建议 |
|---|------|------|------|--------|------|------|----------|------|
| 1 | ABC Packaging | 120人 | 包装 | Mehmet Y. | CEO | m@abc.com | ✅ | 高优先 |
| 2 | Istanbul Foam | 80人 | 建材 | Ahmet K. | Plant Mgr | a@istfoam.com | ✅ | 高优先 |
| 3 | ... | ... | ... | ... | ... | ... | ... | ... |

共 15 家公司 / 22 个决策人

⏸️ 确认后选择执行方式：
  A. 快速试探（≤5家）→ 我直接发一封简短试探邮件
  B. 深度开发（>5家）→ 移交给邮件开发/LinkedIn开发-linkedin-outreach执行
```

### Phase 4A: 快速试探（本技能执行，≤5家）

仅发一封简短试探邮件，不做完整序列：

```
Subject: Quick question about {product_category} — {company_name}

Hi {first_name},

We manufacture {product_category} in Jiangyin, China. Several {country} 
companies use our equipment.

Would it make sense to send you our latest catalog and pricing?

Best regards,
{signature}
```

- 回复了 → 转入 lead-capture 流程 → email-nurture 培育序列
- 没回复 → 不做二次跟进（如需深度跟进，移交获客智能体）

### Phase 4B: 移交获客智能体（>5家深度开发）

```
输出移交文档：

## 移交给邮件开发-email-outreach/LinkedIn开发-linkedin-outreach

客户：Demo-C
目标市场：土耳其 × 包装行业
名单：15家公司/22个决策人（详见上方表格）
建议：邮件+LinkedIn组合拳，优先#1 #2 #5

请用邮件开发-email-outreach的完整序列（域名预热+EQS评分+跟进序列）执行。

→ client-manager.add_timeline: "主动开发名单已生成（土耳其×包装×15家），移交获客智能体执行"
```

---

## 执行规则

| 规则 | 说明 |
|------|------|
| **快速试探最多5家** | 超过5家必须移交给专业的获客智能体 |
| **不做域名预热** | 那是邮件开发-email-outreach的活 |
| **不做LinkedIn序列** | 那是LinkedIn开发-linkedin-outreach的活 |
| **不做完整跟进** | 试探邮件没回复就到此为止 |
| **每封邮件必须个性化** | 至少包含公司名+行业+国家 |
| **记录所有触达** | add_timeline 记录，让获客智能体能接续 |
| **竞品识别** | Apollo显示同行业制造商 → 排除，标记 |

---

## 效果追踪

本技能只追踪名单产出和试探响应：

```
## 本双周名单产出

| 客户 | 目标市场 | 名单数 | 试探数 | 回复数 | 移交获客 |
|------|---------|--------|--------|--------|---------|
| Demo-C | 土耳其×包装 | 15家 | 3家(试探) | 1家(回复) | 12家→邮件开发 |

回复的线索已进入 lead-capture → email-nurture 流程
移交的名单已通知运营人员在获客智能体中执行
```

---

## 注意事项

- **Apollo免费版配额有限**：每月搜索和enrichment次数有上限，优先给高价值市场
- **CAN-SPAM/GDPR**：试探邮件也必须有退订选项
- **运营人员是最终决策人**：名单必须运营人员确认后才执行
- **不抢获客智能体的活**：本技能价值是快速验证市场，不是替代深度开发
