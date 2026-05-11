#!/usr/bin/env bash
# 网站运营-inquiry · 一键安装脚本
# 用法：bash install.sh

set -euo pipefail

# 颜色输出（macOS / Linux 通用）
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
RESET=$'\033[0m'

say() { printf "%s%s%s\n" "$CYAN" "$1" "$RESET"; }
ok()  { printf "%s✓ %s%s\n" "$GREEN" "$1" "$RESET"; }
warn(){ printf "%s⚠ %s%s\n" "$YELLOW" "$1" "$RESET"; }
err() { printf "%s✗ %s%s\n" "$RED" "$1" "$RESET"; }

AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say "== 网站运营-inquiry · 一键安装 =="
echo "智能体目录：$AGENT_DIR"
echo

# -------- 1. 系统环境检查 --------
say "[1/5] 环境检查"

command -v node >/dev/null || { err "未找到 node。请先安装 Node.js 20+（推荐 nvm）"; exit 1; }
NODE_MAJOR=$(node -v | sed -E 's/v([0-9]+)\..*/\1/')
(( NODE_MAJOR >= 20 )) || { err "Node.js 版本需 >= 20，当前 $(node -v)"; exit 1; }
ok "Node.js $(node -v)"

command -v npm >/dev/null && ok "npm $(npm -v)" || { err "未找到 npm"; exit 1; }
command -v python3 >/dev/null && ok "python3 $(python3 --version | awk '{print $2}')" || warn "未找到 python3（个别 GSC 脚本依赖）"

if command -v claude >/dev/null; then
  ok "Claude Code CLI $(claude --version 2>/dev/null | head -1)"
else
  warn "未找到 claude CLI。请从 VSCode Marketplace 安装 Claude Code 插件，或参考 https://claude.ai/code"
fi
echo

# -------- 2. .env 引导 --------
say "[2/5] 环境变量配置"

if [ ! -f "$AGENT_DIR/.env" ]; then
  cp "$AGENT_DIR/.env.example" "$AGENT_DIR/.env"
  ok "已生成 .env（从 .env.example 复制）"
  warn "现在打开 .env 逐项填写你自己申请的 key"
  warn "必填：GSC_CONFIG_PATH / GA4_PROPERTY_ID（其它按需）"
else
  ok ".env 已存在，跳过生成"
fi
echo

# -------- 3. 选择 MCP --------
say "[3/5] MCP 选择"
cat <<'EOM'
本智能体依赖 9 个 MCP 服务：
  [必需]
    - client-manager      客户档案 CRUD
    - site-monitor        网站可用性
    - fetch               外部抓取

  [强烈推荐]
    - search-analytics    GSC + GA4 数据（运营核心）
    - seo-checker         SEO 审计
    - content-tracker     内容管理

  [可选]
    - deployer            一键部署（需 SSH 凭证）
    - memory              长期知识图谱
    - image-generator     博客封面 + 信息图

本脚本不会自动安装 MCP（因为每个 MCP 都是独立 npm 包或 git 仓库）。
请查阅下述任一参考：
  - https://modelcontextprotocol.io          官方 MCP 目录
  - https://www.npmjs.com/search?q=mcp-server 社区 MCP

推荐做法：
  在 ~/.claude/mcp.json 里配置你启用的 MCP，例如：

    {
      "mcpServers": {
        "client-manager": {
          "command": "npx",
          "args": ["-y", "@your-org/mcp-client-manager"]
        },
        ...
      }
    }

配置完成后重启 VSCode，Claude Code 会自动加载。
EOM
echo

# -------- 4. Claude Code 权限配置检查 --------
say "[4/5] Claude Code settings"

SETTINGS="$AGENT_DIR/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  ok "已存在 .claude/settings.json（MCP 权限白名单）"
  echo "  本骨架默认只允许 9 个 MCP 的只读/必要工具。"
  echo "  首次对话时 Claude Code 会为你自动追加白名单，减少后续确认。"
else
  warn ".claude/settings.json 丢失。请检查交付包完整性。"
fi
echo

# -------- 5. 最小自检 --------
say "[5/5] 最小自检"

cd "$AGENT_DIR"
if [ -f "CLAUDE.md" ]; then
  ok "CLAUDE.md 可读"
else
  err "缺少 CLAUDE.md，智能体无法启动"; exit 1
fi

SKILL_COUNT=$(find .claude/skills -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 15 ]; then
  ok "技能文件 $SKILL_COUNT 个"
else
  warn "技能文件数异常（$SKILL_COUNT 个，预期 ≥15）"
fi
echo

# -------- 总结 --------
say "== 安装完成 =="
cat <<EOM

下一步：
  1. 打开 .env 填入你自己的 key（至少 GSC_CONFIG_PATH + GA4_PROPERTY_ID）
  2. 在 ~/.claude/mcp.json 配置你启用的 MCP
  3. 在 VSCode 打开本目录，打开 Claude Code（Cmd+Esc）
  4. 输入："你好，请读 CLAUDE.md 并告诉我你能做什么"

遇到问题：
  - 读 GETTING_STARTED.md 第 6 节 "常见问题"
  - 读 CLAUDE.md 第 7 章 "异常处理"

祝你跑得顺。
EOM
