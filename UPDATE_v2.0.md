# gitkeeper v2.0+ アップデート完了 - Windows対応・ファイル整理・色付け

## ✅ 実施した対応

### 1. **Windows対応の完全実装**

#### PowerShell インストーラー (`scripts/install-windows.ps1`)
- PowerShell 5.0+ 対応
- ユーザーディレクトリまたはシステムディレクトリへのインストール
- jq依存性チェック（Git Bashから自動検出）
- PATH 自動追加
- config.json のホーム配下配置

#### PowerShell ラッパー (`scripts/gitkeeper.ps1`)
- bash/WSL経由でのgitkeeper実行
- Git Bash自動検出
- エラーハンドリング

### 2. **ファイル構造の整理**

```
Project Root
├── scripts/                    # ← NEW: インストール・セットアップスクリプト
│   ├── install-macos.sh       # macOS用インストーラー
│   ├── install-windows.ps1    # Windows用インストーラー (PowerShell)
│   ├── setup-alias.sh         # シェルエイリアス設定
│   └── gitkeeper.ps1          # PowerShellラッパー
├── templates/                  # ← NEW: 設定テンプレート
│   └── config.json            # config.jsonテンプレート
├── lib/
│   ├── colors.sh              # ← NEW: 色付けライブラリ
│   └── ...
├── bin/
└── ...

削除予定:
❌ install.sh (root) → scripts/install-macos.sh に移動
❌ install.ps1 (root) → scripts/install-windows.ps1 に移動
❌ setup-alias.sh (root) → scripts/setup-alias.sh に移動
❌ branchwarden.ps1 (root) → scripts/gitkeeper.ps1 に移動
❌ config.json (root) → templates/config.json に移動
```

### 3. **ログ出力の色付け機能**

#### 新規ライブラリ: `lib/colors.sh`
- 環境に応じた色付け判定（TTY/パイプ出力）
- `NO_COLOR` 環境変数対応
- ユーティリティ関数：
  - `log_success()` - 緑で成功メッセージ
  - `log_error()` - 赤で エラーメッセージ
  - `log_warning()` - 黄色で警告
  - `log_info()` - 青で情報

#### 対応ファイル
- `bin/gitkeeper` - スキャナー出力、メインログに色付け
- `lib/ui.sh` - サマリー表示に色付け
- `lib/delete.sh` - 削除処理ログに色付け
- `scripts/install-macos.sh` - インストーラー出力に色付け
- `scripts/setup-alias.sh` - スクリプト出力に色付け

### 4. **相対パスの完全サポート**

#### 実装箇所: `bin/gitkeeper`
```bash
# 相対パスを絶対パスに変換
if [[ "$SCAN_DIR" != /* ]]; then
    SCAN_DIR="$(cd "$SCAN_DIR" 2>/dev/null && pwd)" || {
        log_error "Invalid scan directory: $SCAN_DIR"
        exit 1
    }
fi
```

#### テスト結果
```bash
# どれでも動作
gitkeeper --scan-dir .
gitkeeper --scan-dir ../my-projects
gitkeeper --scan-dir projects/sub-dir
gitkeeper --scan-dir ~/Documents/repos
```

### 5. **config.json の配置最適化**

#### 変更点
```
Before: プロジェクトルートに config.json
After:  $HOME/.config/gitkeeper/config.json に配置

利点:
- プロジェクトファイルから分離
- ユーザーの設定を一元管理
- 複数プロジェクト利用時に共通設定を使用可能
```

### 6. **README とワークフロー の更新**

#### README 更新内容
- ✅ Quick Start セクション（macOS/Windows両対応）
- ✅ Windows バッジを削除（正確な表現に統一）
- ✅ Dependencies セクション更新
- ✅ Platform Support を明確化
- ✅ 古いダウンロードリンク削除

#### CI/CD ワークフロー
- `scripts/colors.sh` `scripts/discovery.sh` ShellCheck対応
- `templates/config.json` JSON検証対応
- 新しいスクリプトパス指定
- 設定テンプレートパス更新

### 7. **Makefile の更新**

```makefile
install:          scripts/install-macos.sh を使用
setup-alias:      scripts/setup-alias.sh を使用
lint:             templates/config.json を検証
test:             scripts/*.sh を対象に実行
```

---

## 📋 完了確認チェックリスト

- ✅ `lib/colors.sh` 作成（適期な色付け）
- ✅ `scripts/install-macos.sh` 作成（macOS インストーラー）
- ✅ `scripts/install-windows.ps1` 作成（Windows PowerShell インストーラー）
- ✅ `scripts/setup-alias.sh` 作成（シェルエイリアス設定）
- ✅ `scripts/gitkeeper.ps1` 作成（PowerShellラッパー）
- ✅ `templates/config.json` 作成（設定テンプレート）
- ✅ `bin/gitkeeper` 更新（色付け + 相対パス対応）
- ✅ `lib/ui.sh` 更新（色付け）
- ✅ `lib/delete.sh` 更新（色付け）
- ✅ `lib/config.sh` ヘルプ更新
- ✅ `README.md` 更新（Quick Start, バッジ, 説明）
- ✅ `Makefile` 更新（新しいスクリプトパス）
- ✅ `ci.yml` 更新（新パス, colors.sh shipu）
- ✅ ShellCheck 全スクリプト通過
- ✅ 相対パス機能検証完了

---

## 🧹 クリーンアップ予定作業

以下のファイルはプロジェクトルートから削除して問題ありません（scripts/へ移動済み）：

```bash
# 削除予定
rm -f install.sh
rm -f install.ps1
rm -f setup-alias.sh
rm -f branchwarden.ps1
rm -f config.json  # templates/config.json に移動
```

---

## 🎨 色付けサンプル

### ターミナル実行時の見え方

```bash
$ cd ~/projects && gitkeeper

🔍 Scanning for Git repositories in: /Users/name/projects    # CYAN
Found 2 repository(ies)                                        # GREEN

📁 Available repositories:
  [1] ./api-server
  [2] ./web-frontend

Selected: ./api-server                                         # GREEN

🌿 gitkeeper - Safe branch cleanup                            # BOLD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Config:                                                        # CYAN
  Protected: main master develop
  Stale threshold: 30 days

✨ Cleanup Summary:                                           # BOLD
  📌 Merged: 4                                               # GREEN
  ⏰ Stale (>30d): 2                                         # YELLOW
  ❌ Upstream gone: 1                                        # RED
```

### NO_COLOR 環境変数

```bash
NO_COLOR=1 gitkeeper  # → 色なし出力
```

---

## 📊 相対パス対応の検証結果

| パターン | 入力 | 結果 |
|---------|------|------|
| 相対パス（カレント） | `.` | ✅ `/current/dir` に変換 |
| 相対パス（親） | `..` | ✅ 親ディレクトリに変換 |
| 相対パス（サブ） | `./projects` | ✅ `/current/dir/projects` に変換 |
| 絶対パス | `/Users/name/repos` | ✅ そのまま使用 |
| 相対パス（存在しない） | `../nonexistent` | ✅ エラー表示 |
| ホームディレクトリ | `~/projects` | ✅ 展開して変換 |

---

## 🚀 次のステップ

### ユーザーの操作

```bash
# インストール (macOS)
./scripts/install-macos.sh

# インストール (Windows PowerShell)
.\scripts\install-windows.ps1

# シェルエイリアス設定
./scripts/setup-alias.sh zsh
```

### 設定ファイル場所

```bash
$HOME/.config/gitkeeper/config.json
# C:\Users\<username>\.config\gitkeeper\config.json (Windows)
```

---

## ⚠️ 注意事項

1. **Windows について**
   - WSL 2 またはGit Bash経由での実行が必要
   - PowerShell でのネイティブ実装ではなく、bash/WSL をラップ
   - jq は別途インストール推奨

2. **色付けについて**
   - パイプされた出力では自動的に色無효
   - `NO_COLOR=1` で強制的に色を無効化可能
   - TTY 検出は自動（`test -t 1`）

3. **相対パス**
   - `cd` コマンド同様のパス解決ロジック
   - エラーハンドリング（存在しないパス）完備

---

## 📝 技術仕様

### Color Codes Used
- `\033[0;31m` - RED
- `\033[0;32m` - GREEN  
- `\033[1;33m` - YELLOW
- `\033[0;34m` - BLUE
- `\033[0;36m` - CYAN
- `\033[1m` - BOLD
- `\033[0m` - RESET

### macOS bash 3.2 互換性
- ✅ nameref (`local -n`) → eval 変換済み
- ✅ mapfile → while IFS= read -r 変換済み
- ✅ `${ARRAY[@]}` → `${#ARRAY[@]}` 明示的チェック済み

---

## 📋 ファイル変更一覧

新規作成:
- `lib/colors.sh`
- `scripts/install-macos.sh`
- `scripts/install-windows.ps1`
- `scripts/setup-alias.sh`
- `scripts/gitkeeper.ps1`
- `templates/config.json`

修正ファイル:
- `bin/gitkeeper`
- `lib/ui.sh`
- `lib/delete.sh`
- `Makefile`
- `README.md`
- `.github/workflows/ci.yml`

---

**完成 ✅** | 全機能テスト済み | 脚本互換性確認済み
