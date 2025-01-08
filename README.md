# dotfiles
開発環境のセットアップ用dotfilesです。

## インストール方法
```bash
git clone git@github.com:kouichiishikawa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```
## 含まれるもの
- .zshrc - Zshシェルの設定
- .zprofile - ログインシェルの設定
- .gitconfig - Gitの設定
- .ssh/config - SSHの設定（公開設定のみ）
- editors/ - エディタ設定
  ├── settings/ - 各エディタの設定ファイル
  └── keybindings/ - キーバインド設定

## 機能
- 既存のdotfilesの自動バックアップ
- Homebrewのインストール確認
- エラーハンドリング機能付きの安全なインストール
- 視認性の高いカラー出力
- 検証用のテストスクリプト
- エディタ設定の自動セットアップ

## エディタ設定
現在、以下のエディタの設定をサポートしています：
- Cursor
  - settings.json - エディタの基本設定
  - keybindings.json - カスタムキーバインド
各エディタの設定は editors/ ディレクトリで管理され、インストール時に自動的にシンボリックリンクが作成されます。

## 必要要件
- Git
- macOS
- Zsh

## ディレクトリ構成
.
├── .gitignore
├── .zshrc
├── .zprofile
├── .ssh/
│   └── config
├── editors/
│   ├── settings/
│   │   └── cursor.json
│   └── keybindings/
│       └── cursor.json
├── install.sh
└── test.sh
