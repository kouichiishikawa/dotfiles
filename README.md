# Kouichi's dotfiles
開発環境のセットアップ用dotfilesです。

## インストール方法

```bash
git clone git@github.com:kouichiishikawa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## 含まれるもの
- .zshrc
  - Zshシェルの設定
- .zprofile
  - ログインシェルの設定
- .gitconfig
  - Gitの設定
- .ssh/config
  - SSHの設定（公開設定のみ）

## 機能
- 既存のdotfilesの自動バックアップ
- Homebrewのインストール確認
- エラーハンドリング機能付きの安全なインストール
- 視認性の高いカラー出力
- 検証用のテストスクリプト
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
├── install.sh
└── test.sh
