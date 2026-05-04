#!/usr/bin/env python3
"""
check_project.py — Sorayomi プロジェクト整合性チェッカー

Xcodeプロジェクトとディスク上のファイルの乖離を検出します。
使い方: python3 check_project.py
"""

import os
import re
import sys

PBXPROJ = "Sorayomi.xcodeproj/project.pbxproj"
SOURCE_DIR = "Sorayomi"

# ── 1. pbxproj からファイル名を抽出 ─────────────────────────────────────────

with open(PBXPROJ, "r") as f:
    content = f.read()

# PBXFileReference の path 値をすべて取得（引用符あり/なし両対応）
registered_names = set(re.findall(r'path = "?([^";]+\.[a-zA-Z0-9]+)"?;', content))

# ── 2. ディスク上のファイルを収集 ────────────────────────────────────────────

TRACKED_EXTENSIONS = {".swift", ".m", ".mm", ".plist",
                      ".storekit", ".entitlements", ".xcprivacy",
                      ".mp3", ".m4a", ".wav"}

# フォルダ型リソース（個別ファイルではなくフォルダごと登録されるもの）
FOLDER_RESOURCES = {".xcassets", ".xcframework", ".bundle"}

IGNORED_DIRS = {".git", "DerivedData", "build", "tmp", "output",
                "__pycache__", ".build", "AppStore"}

def is_inside_folder_resource(path):
    """xcassets 等のフォルダ型リソース内のファイルは個別登録不要"""
    parts = path.split(os.sep)
    return any(any(p.endswith(ext) for ext in FOLDER_RESOURCES) for p in parts)

disk_files = set()       # 個別登録が必要なファイル名
disk_folders = set()     # フォルダ型リソース名（xcassets など）

for root, dirs, files in os.walk(SOURCE_DIR):
    dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]

    # フォルダ型リソースを収集
    for d in list(dirs):
        _, ext = os.path.splitext(d)
        if ext in FOLDER_RESOURCES:
            disk_folders.add(d)

    # xcassets 等の中にいる場合はスキップ
    if is_inside_folder_resource(root):
        continue

    for f in files:
        _, ext = os.path.splitext(f)
        if ext in TRACKED_EXTENSIONS:
            disk_files.add(f)

# フォルダ型リソースもチェック対象に加える
all_disk_resources = disk_files | disk_folders

# ── 3. 差分を表示 ────────────────────────────────────────────────────────────

# ビルド成果物など無視すべき登録済みエントリ
PHANTOM_IGNORE_EXTENSIONS = {".app", ".framework", ".dylib", ".o"}

# ディスクにあるがプロジェクト未登録
missing_from_project = sorted(
    f for f in all_disk_resources if f not in registered_names
)

# プロジェクトに登録されているがディスクにない（ファントム）
phantom_in_project = sorted(
    f for f in registered_names
    if f not in all_disk_resources
    and not f.startswith("/")
    and not f.startswith("$(")
    and not any(f.endswith(ext) for ext in PHANTOM_IGNORE_EXTENSIONS)
)

# ── 4. UUID 重複チェック（定義行の重複のみ） ─────────────────────────────────

def_pattern = re.compile(r'^\t\t([0-9A-F]{24}) /\*', re.MULTILINE)
defined_uuids = def_pattern.findall(content)
def_seen = {}
for uuid in defined_uuids:
    def_seen[uuid] = def_seen.get(uuid, 0) + 1
dup_defs = {u: c for u, c in def_seen.items() if c > 1}

# ── 5. レポート出力 ──────────────────────────────────────────────────────────

ok = True

if missing_from_project:
    ok = False
    print("🚨 ディスクにあるがプロジェクト未登録（ビルドに含まれない）:")
    for f in missing_from_project:
        print(f"   ✗ {f}")
else:
    print("✅ 未登録ファイル: なし")

print()

if phantom_in_project:
    ok = False
    print("🚨 プロジェクトに登録されているがディスクにない（ファントム）:")
    for f in phantom_in_project:
        print(f"   ✗ {f}")
else:
    print("✅ ファントムエントリ: なし")

print()

if dup_defs:
    ok = False
    print("🚨 UUID 重複定義（プロジェクト破損の可能性）:")
    for uuid, count in sorted(dup_defs.items()):
        print(f"   ✗ {uuid} が {count} 回定義されています")
else:
    print("✅ UUID 重複: なし")

print()

if ok:
    print("🎉 プロジェクトの整合性に問題はありません。")
    sys.exit(0)
else:
    print("⚠️  上記の問題を修正してからビルドしてください。")
    sys.exit(1)
