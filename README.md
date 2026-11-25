# lzpilot

一個入口，依任務選擇 playbook，照步驟完成工作，並交出證據。developer 和非 developer 都可以使用。

## 安裝

Claude Code：

```
/plugin marketplace add ChenLiZhan/lzpilot
/plugin install lzpilot@lzpilot
```

claude.ai 或 Claude 桌面版：Customize → Plugins → Add marketplace，輸入 `ChenLiZhan/lzpilot`。

## 使用

輸入 `/lzpilot:go`，後面接你的需求。

## 結構

```
.claude-plugin/marketplace.json   marketplace
plugins/lzpilot/                  安裝的內容
  skills/go/SKILL.md              入口、路由、每次都要遵守的規則、回答方式
  skills/go/playbooks/            一個任務一本
  skills/go/principles/           一條原則一個檔
  evals/                          行為測試
scripts/check.sh                  結構檢查
```

## 知識放在哪裡

lzpilot 只放跨專案通用的 playbook。其他知識放在下面的地方：

- 專案專屬的知識：專案的 `CLAUDE.md` 或專案的 `.claude/skills/`。
- 個人偏好：`~/.claude/CLAUDE.md`。
- 工作上的知識：只放在公司的 repo，不要放進 lzpilot。

維護規則在 [CLAUDE.md](CLAUDE.md)。
