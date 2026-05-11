# inquiry · 上手指南

本智能体是一位可长期托管的网站运营执行官，目标是让一个人同时跑好多个 B2B 外贸独立站：每日巡检、增长执行、月度报告、GSC/GA4 数据全自动、AI 搜索引用监控、CTR 优化、GEO 攻防。

面向人群：独立站站长 / 数字运营 / 小型服务团队。

---

## 0. 三分钟速览

- 入口文件：**CLAUDE.md** — 智能体的身份、流程、禁止行为
- 技能 21 个：**`.claude/skills/`** — 每个文件就是一条可调用的工作流
- 客户档案：通过 `client-manager` MCP 管理（不需要手动维护文件）
- 数据来源：`search-analytics` MCP（GSC + GA4 全自动，无需手动导 CSV）
- 运行形态：在 VSCode + Claude Code 插件里对话使用

---

## 1. 系统要求

| 项目 | 要求 |
|---|---|
| 操作系统 | macOS 12+ / Linux / Windows 11 WSL2 |
| Node.js | v20+（推荐 nvm 管理） |
| Python | 3.10+（仅用于个别 GSC 脚本） |
| VSCode | 最新版 |
| Claude Code 插件 | VSCode Marketplace 搜 "Claude Code" |
| Claude 账户 | [claude.ai](https://claude.ai)，推荐 Pro 或 Max 订阅 |

---

## 2. 安装流程

### 2.1 克隆或解压智能体

把本目录放到你的工作区里，例如：

```bash
mkdir -p ~/ai-agents && cd ~/ai-agents
# 把本目录复制进来：ai-agents/web-ops/
```

### 2.2 安装 MCP 依赖

智能体依赖 9 个 MCP 服务，`install.sh` 会引导你配置：

```bash
cd web-ops
bash install.sh
```

脚本会：
1. 检查 Node.js / Python / VSCode / Claude Code 插件版本
2. 询问你要启用哪些 MCP（默认全开）
3. 指导你生成 `.env`（从 `.env.example` 复制后填值）
4. 生成本地 `~/.claude/mcp.json`（用户级 MCP 配置）
5. 检查每个 MCP 是否能正常启动

### 2.3 首次对话

在 VSCode 里：

1. 打开 `web-ops/` 目录
2. 打开 Claude Code 面板（侧边栏 Claude 图标 / `Cmd+Esc`）
3. 输入 `你好，请读 CLAUDE.md 并告诉我你能做什么`

智能体会回应它的能力清单 + 当前客户列表（通过 client-manager MCP 查询）。

---

## 3. 第一个客户：5 分钟跑通

### 3.1 注册客户到 client-manager

```
把新客户录入 client-manager：
- 公司名：Demo 玩具工厂
- 网站：https://demo-toy.com
- 行业：儿童玩具
- 国家：中国
- 联系人：张三 / zhang@demo-toy.com
```

智能体会调用 `mcp__client-manager__add_client` 完成录入，返回 client_id。

### 3.2 完成数据源授权

跟着以下文档给客户站配置数据源：

- [客户版/GSC授权操作指南.md](客户版/GSC授权操作指南.md) — 让 GSC 把搜索数据给到 MCP
- [客户版/GA4授权操作指南.md](客户版/GA4授权操作指南.md) — 让 GA4 把流量数据给到 MCP

核心动作：把服务账号邮箱加到 GSC 属性和 GA4 属性，授 Full User 权限。

### 3.3 跑第一次巡检

```
Demo 玩具工厂 每日巡检
```

智能体会走 `daily-ops` 技能，7+1 项检查：
1. 网站可用性
2. GSC 异常
3. 排名波动
4. 竞品扫描
5. 昨日数据
6. 索引提交
7. 结构化数据验证
8. 问题修复（发现的问题现场改）

### 3.4 跑一次主动增长

```
Demo 玩具工厂 今日任务
```

智能体会走 `daily-growth` 技能，从 7 个维度里用 GSC 数据驱动选**最高价值**的一项做下去。

---

## 4. 核心能力地图

打开 `CLAUDE.md` 读第 3-5 章是最快的。精简版：

| 频次 | 指令 | 产出 |
|---|---|---|
| 每日 | `[客户] 每日巡检` | 健康检查 + 问题闭环修复 |
| 每日 | `[客户] 今日任务` | 7 维度增长引擎选一项做 |
| 每日 | `[客户] 今日简报` | 可发微信群的日报 |
| 每周 | `[客户] 周检查` | 深度周检 + 100 分健康评分 |
| 每周 | `[客户] 排名追踪` | 关键词趋势 + 机会词识别 |
| 每双周 | `[客户] 写博客：[主题]` | 12 阶段博客生产 |
| 每月 | `[客户] 开始本月运营` | 数据分析 + 选题 |
| 每月 | `[客户] 生成月报` | 专业月报 |
| 每季度 | `[客户] 季度复盘` | 深度复盘 + 下季度规划 |

---

## 5. 目录结构

```
web-ops/
├── CLAUDE.md                 ← 智能体定义（必读）
├── .claude/
│   ├── settings.json         ← MCP 权限白名单
│   └── skills/               ← 21 个技能
├── 升级日志.md                ← 版本演进
├── 案例库/                   ← 实战案例（占位）
├── 客户版/                   ← 给客户看的入职资料
│   ├── 01-客户入职欢迎包.md
│   ├── 02-月度运营报告模板-专业版.md
│   ├── GSC授权操作指南.md
│   ├── GA4授权操作指南.md
│   ├── 站外账号配置指南.md
│   ├── email-clarity-激活操作包.md
│   ├── 每日工作看板.md
│   ├── 网站运营服务说明.md
│   └── inquiry 智能体-交付说明.md
├── 模板库/                   ← 月报/周检/ROI 模板
├── reports/                  ← 自动巡检产物
├── scripts/                  ← GSC 辅助脚本
├── .env.example              ← 环境变量模板
├── install.sh                ← 一键安装脚本
└── GETTING_STARTED.md        ← 本文件
```

---

## 6. 常见问题

**Q：必须 9 个 MCP 都装吗？**
A：不。最小可用子集是 `client-manager` + `site-monitor` + `fetch`。其他按需启用（比如不用 GSC/GA4 就不装 `search-analytics`）。

**Q：企业微信播报是必需的吗？**
A：不。`reports/` 目录默认只生成 markdown 文件，你手动发微信也行。想自动推送就在 `.env` 填 `WECOM_WEBHOOK_URL`。

**Q：智能体能直接改我的客户网站吗？**
A：只能通过你授权的 `deployer` MCP（走 SSH + 部署脚本）。每次部署需要你在 Claude Code 里确认。

**Q：如何让智能体"记住"我？**
A：Claude Code 有 auto memory 机制（见 [anthropic.com/claude-code](https://www.anthropic.com/claude-code)），智能体会在 `~/.claude/projects/<project>/memory/` 积累长期记忆。你也可以用 `/memory` 查看/管理。

---

## 7. 下一步

1. 读 [CLAUDE.md](CLAUDE.md) — 完整能力 + 禁止行为 + 4 级运营节奏
2. 读 [客户版/inquiry 智能体-交付说明.md](客户版/inquiry 智能体-交付说明.md) — 面向你的客户的服务介绍
3. 读 [客户版/01-客户入职欢迎包.md](客户版/01-客户入职欢迎包.md) — 接入新客户的标准欢迎包
4. 接入第一个客户，跑完第 3 节的 5 分钟闭环

祝你跑得顺。
