#!/usr/bin/env bash
# 結構檢查。commit 前執行：scripts/check.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$ROOT/plugins/lzpilot/skills/go"

python3 -I - "$SKILL_DIR" <<'PY'
import re, sys, pathlib

skill_dir = pathlib.Path(sys.argv[1])
plugin_dir = skill_dir.parents[1]
errors = []

def frontmatter(path):
    text = path.read_text(encoding="utf-8")
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fields = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            fields[k.strip()] = v.strip()
    return fields

def parse_list(value):
    value = value.strip()
    if not (value.startswith("[") and value.endswith("]")):
        return None
    inner = value[1:-1].strip()
    return [x.strip().strip("'\"") for x in inner.split(",")] if inner else []

skill_md = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
skill_fm = frontmatter(skill_dir / "SKILL.md") or {}
description = skill_fm.get("description", "")

# 0. SKILL.md 的限制
# frontmatter 只用 name 和 description，claude.ai 上傳才不會被拒絕。
for field in sorted(set(skill_fm) - {"name", "description"}):
    errors.append(f"SKILL.md：frontmatter 不允許欄位 {field}")
# description 每個 session 都常駐，而且過長會被截斷。
DESCRIPTION_MAX = 500
if len(description) > DESCRIPTION_MAX:
    errors.append(f"SKILL.md：description 有 {len(description)} 字元，上限 {DESCRIPTION_MAX}")
# 對話壓縮後只會重新附上 SKILL.md 的前 5,000 tokens。中文約 1 字 1 token，所以留餘裕。
SKILL_MAX = 4000
if len(skill_md) > SKILL_MAX:
    errors.append(f"SKILL.md：全文 {len(skill_md)} 字元，上限 {SKILL_MAX}")

def index_rows(section):
    m = re.search(rf"^## {section}\n(.*?)(\n## |\Z)", skill_md, re.S | re.M)
    if not m:
        return {}
    return {name: row for name, row in re.findall(r"^\| `([^`]+)` \|(.*)$", m.group(1), re.M)}

def index_names(section):
    return set(index_rows(section))

# 1. playbook 檔案與索引一致
playbook_files = {p.stem: p for p in (skill_dir / "playbooks").glob("*.md")}
indexed = index_names("Playbooks")
for name in sorted(set(playbook_files) - indexed):
    errors.append(f"playbook 沒有列在 SKILL.md 索引：{name}")
for name in sorted(indexed - set(playbook_files)):
    errors.append(f"索引裡的 playbook 沒有檔案：{name}")

# 2. playbook frontmatter 欄位與值
ALLOWED = {"style": {"technical", "plain", "auto"}}
playbook_rows = index_rows("Playbooks")
for name, path in sorted(playbook_files.items()):
    fm = frontmatter(path)
    if fm is None:
        errors.append(f"{name}：沒有 frontmatter")
        continue
    for field in ("needs", "style", "triggers"):
        if field not in fm:
            errors.append(f"{name}：缺少欄位 {field}")
    for field, allowed in ALLOWED.items():
        if field in fm and fm[field] not in allowed:
            errors.append(f"{name}：{field} 的值 '{fm[field]}' 不在 {sorted(allowed)}")
    for field in ("needs", "triggers"):
        if field in fm and parse_list(fm[field]) is None:
            errors.append(f"{name}：{field} 要寫成 [a, b] 格式")
    # 3. 每個觸發詞都要出現在 SKILL.md 索引那一列的「何時用」，路由才看得到
    row = playbook_rows.get(name, "")
    for word in parse_list(fm.get("triggers", "[]")) or []:
        if word and word not in row:
            errors.append(f"{name}：觸發詞 '{word}' 不在 SKILL.md 索引那一列")

# 4. principle 檔案與索引一致
principle_files = {p.stem for p in (skill_dir / "principles").glob("*.md")}
p_indexed = index_names("Principles")
for name in sorted(principle_files - p_indexed):
    errors.append(f"principle 沒有列在 SKILL.md 索引：{name}")
for name in sorted(p_indexed - principle_files):
    errors.append(f"索引裡的 principle 沒有檔案：{name}")

# 5. 不准寫死模型名稱；術語只用 playbook
BANNED = [
    (re.compile(r"claude-(opus|sonnet|haiku|fable)-\d|gemini-\d"), "寫死了模型名稱"),
    (re.compile(r"劇本|情境|scenario", re.I), "術語要用 playbook"),
]
for path in plugin_dir.rglob("*.md"):
    text = path.read_text(encoding="utf-8")
    for pattern, message in BANNED:
        for m in pattern.finditer(text):
            errors.append(f"{path.relative_to(plugin_dir)}：{message}（'{m.group(0)}'）")

if errors:
    print("檢查失敗：")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
print(f"結構檢查通過：{len(playbook_files)} 本 playbook、{len(principle_files)} 條 principle。")
PY

claude plugin validate "$ROOT/plugins/lzpilot"
claude plugin validate "$ROOT"
