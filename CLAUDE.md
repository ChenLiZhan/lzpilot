# lzpilot 維護規則

這份檔案給「開發 lzpilot 的 agent」看。使用 lzpilot 時的規則在 `plugins/lzpilot/skills/go/SKILL.md`，不要混在一起。

## 設計決策

- 一個 plugin，只有一個 skill：`go`，指令是 `/lzpilot:go`。
- playbook 和 principle 都是 `skills/go/` 底下的 md 檔，不是獨立的 skill。這樣選單只會出現一個入口。
- 依任務選 playbook，不依使用者身分。同一個 plugin 同時給 developer 和非 developer 使用。
- 每次都要遵守的規則（優先順序、自主權、外部內容、證據、秘密、回答方式）寫在 SKILL.md 裡。原因：對話壓縮後，只有 SKILL.md 會被重新附上，獨立檔案可能遺失。
- 只有「有時才需要」的內容放在獨立檔案：playbook、principle。
- 不建 `workflows/`。兩本 playbook 需要相同步驟時，讓一本 playbook 引用另一本。
- 允許自動觸發，但 description 要窄。description 最多放 10 個類別詞，不放每本 playbook 的觸發詞。
- repo 是 public。不要放任何工作內容或個人資料（見「去識別化」）。

## 語言

- 檔名、資料夾名、frontmatter 欄位名、工具名、術語：英文。
- `description`：中英都寫。
- 步驟、principle 內文、回覆規格：繁體中文。句子照 STE 規則寫：一句只講一件事、短句、主動語態。
- 術語固定用 playbook、principle、fallback、eval、case。不要寫「劇本」「情境」「scenario」。

## 新增一本 playbook

1. 在 `skills/go/playbooks/` 新增 `<name>.md`。檔名用英文 kebab-case。
2. frontmatter 寫 3 個欄位：
   - `needs`：需要的工具，例如 `[Bash]`。
   - `style`：`technical`、`plain` 或 `auto`。
   - `triggers`：觸發詞，中英都寫，例如 `[壞了, 連不上, broken]`。
3. 內文寫「步驟」和「回覆」兩節。「回覆」要寫出必須交出的證據。
4. 在 `SKILL.md` 的 Playbooks 表格加一列。「何時用」欄位要包含每個觸發詞。
5. 新任務類型和現有類別詞都不符合時，才在 description 加一個類別詞。
6. 在 `plugins/lzpilot/evals/` 加 case，其中至少一個是容易選錯 playbook 的請求。
7. 執行 `scripts/check.sh`。

playbook 不可以寫任何放寬自主權的句子。自主權只由 SKILL.md 決定。

## 新增一條 principle

1. 在 `skills/go/principles/` 新增 `<name>.md`，寫規則和何時適用。
2. 在 `SKILL.md` 的 Principles 表格加一列：`` | `<name>` | 何時適用 | ``。
3. 執行 `scripts/check.sh`。

## 測試

- 結構檢查：`scripts/check.sh`。commit 前一定要執行。它也檢查 SKILL.md 的長度上限（4,000 字元）和 description 上限（500 字元）。
- 乾淨環境：在 repo 根目錄執行下面的指令。它只會載入內建 skill 和 lzpilot，不會載入其他 plugin、`~/.claude/CLAUDE.md` 或個人設定。
  ```
  claude --setting-sources project,local --plugin-dir plugins/lzpilot
  ```
- 行為測試：case 放在 `plugins/lzpilot/evals/`。`claude plugin eval` 只會到 plugin 資料夾底下找 case。
  ```
  claude plugin eval plugins/lzpilot
  ```
  寫第一個 case 前，先用 `claude plugin eval --help` 查 case 的格式。
- 不要在 task 進行中修改 skill。發現 skill 有問題，記下來，另外開一個 commit 處理。

## 發布

1. `plugins/lzpilot/.claude-plugin/plugin.json` 的 `version` +1。
2. 執行 `scripts/check.sh`。
3. commit，push。
4. 各機器執行 `claude plugin update lzpilot@lzpilot`。
5. claude.ai：marketplace 已開啟 Sync automatically，push 後會自動同步。要確認時，到 Plugins → Add → Manage marketplaces，看 Synced commit 是不是最新的 commit。沒有更新，就從 lzpilot 那一列的 ⋯ 點 Check for updates。plugin 頁面的 Version 要重新整理頁面才會變。

## 去識別化

- 不要 commit 工作上的系統名稱、內部網址、ticket 編號、同事名字。
- eval case 和問題紀錄只寫通用類別，加上去識別化的重現句子。
- 不要 commit 任何秘密。

## 不要做

- 不要在 skill 檔裡寫死模型名稱。
- 不要新增第二個 skill。需要新功能時，新增 playbook。
- SKILL.md 的 frontmatter 只用 `name` 和 `description`。其他欄位可能讓 claude.ai 拒絕上傳。
