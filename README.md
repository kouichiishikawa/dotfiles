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
- .zshrc - Zshシェルの設定
- .zprofile - ログインシェルの設定
- .gitconfig - Gitの設定
- .ssh/config - SSHの設定（公開設定のみ）
- editors/ - エディタ設定
  ├── settings/ - 各エディタの設定ファイル
  ├── keybindings/ - キーバインド設定
  └── extensions/ - 拡張機能リスト
```

## 機能
```
- 既存のdotfilesの自動バックアップ
- Homebrewのインストール確認
- エラーハンドリング機能付きの安全なインストール
- 視認性の高いカラー出力
- 検証用のテストスクリプト
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

## ディレクトリ構成
```
.
├── .gitignore
├── .zshrc
├── .zprofile
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
├── install.sh
└── test.sh
```
