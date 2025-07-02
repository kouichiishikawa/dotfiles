# Kouichi's Dotfiles
![dotfiles](https://github.com/user-attachments/assets/31857947-4256-409c-afac-2fec6065c495)

これはkouichiishikawaの開発環境のセットアップ用dotfilesです。

## インストール方法
```bash
git clone git@github.com:kouichiishikawa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## 含まれるもの
```
- .zshrc - Zshシェルの設定（Python環境設定含む）
- .zprofile - ログインシェルの設定
- .gitconfig - Gitの設定
- .ssh/config - SSHの設定（公開設定のみ）
- editors/ - エディタ設定
  ├── settings/ - 各エディタの設定ファイル
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
- エラーハンドリング機能付きの安全なインストール
- 自動ロールバック機能
- 包括的な設定検証機能
- 視認性の高いカラー出力
- エディタ設定の自動セットアップ
- エディタ拡張機能の自動インストール
```

## エディタ設定
現在、以下のエディタの設定をサポートしています：
```
- VSCode
  - settings.json - エディタの基本設定
  - keybindings.json - カスタムキーバインド
  - extensions.txt - インストール済み拡張機能のリスト

- Cursor
  - settings.json - エディタの基本設定
  - keybindings.json - カスタムキーバインド
  - extensions.txt - インストール済み拡張機能のリスト
```
各エディタの設定は editors/ ディレクトリで管理され、インストール時に自動的にシンボリックリンクが作成されます。
- 設定ファイルのシンボリックリンク作成
- 既存の設定ファイルのバックアップ
- 拡張機能の自動インストール

## 必要要件
```
- Git
- macOS
- Zsh
- コマンドラインツール
  - VSCode: `code` コマンド
  - Cursor: `cursor` コマンド
```

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
# Python開発用
py          # python3
pip         # python3 -m pip
venv        # python3 -m venv
jl          # jupyter lab
jn          # jupyter notebook
pf          # pip freeze
pr          # pip install -r requirements.txt

# 一般用
ll          # ls -la
g           # git
dc          # docker-compose
```

## ディレクトリ構成
```
.
├── .gitignore
├── .zshrc          # Python環境設定含む
├── .zprofile
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
