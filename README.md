# Kouichi's Dotfiles
![dotfiles](https://github.com/user-attachments/assets/31857947-4256-409c-afac-2fec6065c495)

これはkouichiishikawaの開発環境のセットアップ用dotfilesです。

## インストール方法
```bash
git clone git@github.com:kouichiishikawa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

- リンクするのは `.zshrc` `.zprofile` `.gitconfig` `.config/starship.toml`（→ `~/.config/starship.toml`）だけ（`install.sh` の `LINK_FILES`）。どのフォルダから実行しても同じ結果になる
- リンクだけ作るときは `./install.sh --links-only`
- Git の名前とメールアドレスはリポジトリに載せず、手元の `~/.gitconfig.local` に置く（`.gitconfig` が `[include]` で読む）
  ```bash
  git config --file ~/.gitconfig.local user.name  "<名前>"
  git config --file ~/.gitconfig.local user.email "<メールアドレス>"
  ```
- コミット前に gitleaks で秘密情報を検査する（`.githooks/pre-commit`。`install.sh` が `core.hooksPath` を設定する）

## 含まれるもの
```
- .zshrc - Zshシェルの設定（mise・starship・fzf・zoxide・atuin・zsh のプラグイン）
- .config/starship.toml - プロンプト（starship）の設定
- .zprofile - ログインシェルの設定
- .gitconfig - Gitの設定（SSH推奨設定含む。user は ~/.gitconfig.local）
- .githooks/pre-commit - gitleaks による秘密情報の検査
- archive/ - 使わなくなった古いファイルの退避先
- .ssh/config - GitHub用SSH設定（ED25519鍵使用）
- editors/ - エディタ設定
  ├── settings/ - 各エディタの設定ファイル（自動整形設定含む）
  ├── keybindings/ - キーバインド設定
  └── extensions/ - 拡張機能リスト
- install.sh - メインインストールスクリプト
- rollback.sh - ロールバック用スクリプト
- test.sh - 設定検証スクリプト
```

## 機能
```
- 既存のdotfilesの自動バックアップ
- Homebrewのインストール確認
- Python開発環境の自動構築 (pyenv, Poetry, Jupyter)
- GitHub SSH接続の自動設定（ED25519鍵使用）
- エラーハンドリング機能付きの安全なインストール
- 自動ロールバック機能
- 包括的な設定検証機能
- 視認性の高いカラー出力
- エディタ設定の自動セットアップ
- エディタ拡張機能の自動インストール
- コード品質維持（保存時自動整形）
```

## エディタ設定
現在、以下のエディタの設定をサポートしています：
```
- VSCode
  - settings.json - エディタの基本設定
  - keybindings.json - カスタムキーバインド
  - extensions.txt - インストール済み拡張機能のリスト

- Cursor
  - settings.json - エディタの基本設定（保存時自動整形有効）
  - keybindings.json - カスタムキーバインド
  - extensions.txt - インストール済み拡張機能のリスト
```
各エディタの設定は editors/ ディレクトリで管理され、インストール時に自動的にシンボリックリンクが作成されます。

### Cursorの自動整形設定
- 保存時に最終行へ改行を自動挿入
- 保存時に最終行以降の空行を自動削除
- 保存時に末尾の空白を自動トリミング
- 保存時にコードを自動整形

### インストール処理
- 設定ファイルのシンボリックリンク作成
- 既存の設定ファイルのバックアップ
- 拡張機能の自動インストール

## 必要要件
```
- Git
- macOS
- Zsh
- SSH鍵（ED25519推奨）
- コマンドラインツール
  - VSCode: `code` コマンド
  - Cursor: `cursor` コマンド
```

## SSH設定
GitHub接続にはSSH方式を使用します：
```bash
# SSH鍵の生成（初回のみ）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 公開鍵をGitHubに登録
# https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub

# 接続テスト
ssh -T git@github.com
```

### 自動設定される内容
- GitHub用SSH設定（`.ssh/config`）
- HTTPS URLの自動SSH変換（`.gitconfig`）
- macOSキーチェーンへの鍵登録

## Python開発環境
自動で以下のPython開発環境が構築されます：
```
- pyenv - Python バージョン管理
  - Python 3.11.9 の自動インストール
  - グローバル Python バージョンの設定
- Poetry - パッケージ・仮想環境管理
  - プロジェクト内仮想環境作成の設定
  - 公式インストーラーによる最新版インストール
- pip 設定
  - 仮想環境外での pip 実行を禁止
  - キャッシュディレクトリの設定
- Jupyter 設定
  - 設定ディレクトリの作成
  - エイリアス設定 (jl, jn)
```

## 便利なエイリアス
```bash
# 一般用
ls          # eza
ll          # eza -la --git
tree        # eza --tree
cat         # bat（ページャーなし）
z <dir>     # zoxide
Ctrl+R      # atuin（履歴検索）
Ctrl+T      # fzf（ファイル検索）
edit / o    # VS Code で開く
py          # python3
g           # git
dc          # docker-compose
```

## ディレクトリ構成
```
.
├── .gitignore
├── .zshrc
├── .zprofile
├── .config/
│   └── starship.toml
├── .gitconfig
├── .ssh/
│   └── config
├── editors/
│   ├── settings/
│   │   ├── vscode.json
│   │   └── cursor.json
│   ├── keybindings/
│   │   ├── vscode.json
│   │   └── cursor.json
│   └── extensions/
│       ├── vscode.txt
│       └── cursor.txt
├── install.sh      # メインインストール（エラーハンドリング付き）
├── rollback.sh     # ロールバック機能
├── test.sh         # 設定検証（CI/CD対応）
└── README.md
```

## 新機能の使い方

### ロールバック機能
インストールに失敗した場合やもとに戻したい場合：
```bash
# インタラクティブにバックアップを選択
./rollback.sh

# 特定のバックアップを指定
./rollback.sh ~/.dotfiles_backup/20240101_120000
```

### 設定検証
インストール後の設定確認：
```bash
# 全設定の検証実行
./test.sh

# 結果例
Testing symlinks...
✓ .zshrc -> /Users/user/dotfiles/.zshrc
✓ .gitconfig -> /Users/user/dotfiles/.gitconfig
...
Testing Python environment...
✓ pyenv is installed
✓ Python 3.11 is installed
✓ Poetry is installed
...
================================
Test Summary:
Passed: 15
Failed: 0
Total:  15
================================
All tests passed!
```

### Pandas開発の始め方
```bash
# プロジェクト作成
mkdir my-pandas-project && cd my-pandas-project

# Poetry初期化
poetry init

# Pandas環境構築
poetry add pandas numpy matplotlib jupyter

# 仮想環境に入る
poetry shell

# Jupyter Lab起動
jl
```


---
最終更新: 2026年03月18日
