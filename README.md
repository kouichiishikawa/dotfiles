# Kouichi's Dotfiles
![dotfiles](https://github.com/user-attachments/assets/31857947-4256-409c-afac-2fec6065c495)

Mac の作業環境（シェル・Homebrew・アプリ・各ツールの設定）を、新しい Mac でもこのリポジトリと `./install.sh` で同じ状態に戻すためのもの。

**このリポジトリは公開している。**トークン・鍵・MCP の設定・メールアドレス・社名の入った設定は載せない。名前・メールアドレス・署名の鍵は手元の `~/.gitconfig.local` に置く。

## 新しい Mac での手順

上から順に進める。`./install.sh` は何度実行しても同じ結果になる（入っているものは触らない）ので、途中で止まったら直してもう一度実行すればよい。

### 1. サインインする
- Apple アカウントでサインインし、App Store にもサインインしておく（Brewfile の App Store のアプリ（`mas`）を入れるのに要る）

### 2. 1Password を入れる
SSH の鍵（`.ssh/config`）とコミットの署名（`.gitconfig` の `op-ssh-sign`）が 1Password のデスクトップアプリに頼っているので、最初に入れる。

1. https://1password.com/downloads/mac から入れてサインインする（Homebrew を先に入れたなら `brew install --cask 1password` でもよい。`install.sh` も無ければ入れる）
2. 1Password の設定 > 開発者 で「SSH エージェントを使用」を有効にする
3. GitHub に登録してある SSH 鍵が 1Password に入っていることを確かめる

### 3. dotfiles を clone して install.sh を実行する
```bash
xcode-select --install   # git を使うために Command Line Tools を入れる（入っていれば何もしない）
git clone https://github.com/kouichiishikawa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # 何をするかを一覧で見る（何も変えない）
./install.sh
```

最初の clone は HTTPS で行う（公開リポジトリなので鍵が要らない）。リンクの後は `.gitconfig` の `insteadOf` で、GitHub への接続は SSH（1Password）になる。

`install.sh` が行うこと（この順）:

| 順 | 内容 | すでにあるとき |
|---|---|---|
| 1 | Xcode Command Line Tools | 何もしない（無ければ入れて止まるので、終わったらもう一度実行する） |
| 2 | Homebrew | 何もしない |
| 3 | 1Password のデスクトップアプリ | 何もしない |
| 4 | `brew bundle --file=Brewfile` | `brew bundle check` が通れば何もしない |
| 5 | リンク: `.zshrc` `.zprofile` `.gitconfig`、`.config/` の `starship.toml` `ghostty/config` `git/ignore` `mise/config.toml` `cmux/cmux.json`（`LINK_FILES`）、`.ssh/config`、VS Code と Cursor の `settings.json` `keybindings.json`（アプリがあるときだけ） | 正しいリンクなら何もしない。別のファイルがあれば `~/.dotfiles_backup/<日時>/` に退避してからリンクする |
| 6 | VS Code と Cursor の拡張機能（`editors/extensions/*.txt`） | 入っているものは入れない |
| 7 | `mise install`（Node の LTS）と `uv python install 3.12 --default`（`~/.local/bin/python3`） | 入っていれば何もしない |
| 8 | dotfiles の `core.hooksPath=.githooks`（コミット前に gitleaks で秘密情報を検査） | 何もしない |
| 9 | macOS の設定（`macos/defaults.sh`。Dock・Finder・キーボード・トラックパッド） | 毎回、入れるかを聞く（Enter で入れない） |
| 10 | 「人がやること」の一覧を出す | — |

最後に「作る・入れる / リンク / 退避」の件数を出す。2 回目以降は、変わったものが無ければすべて 0 になる。

### 4. Git の名前と署名（`~/.gitconfig.local`）
`.gitconfig` は最後に `[include]` で `~/.gitconfig.local` を読む。ここだけはリポジトリに載せない。
```bash
git config --file ~/.gitconfig.local user.name  "<名前>"
git config --file ~/.gitconfig.local user.email "<メールアドレス>"
git config --file ~/.gitconfig.local user.signingkey "<1Password の SSH 公開鍵>"   # 1Password の鍵の「公開鍵」をそのまま
ssh -T git@github.com   # "successfully authenticated" と出れば通っている
```
`commit.gpgsign=true` なので、署名ができないとコミットが止まる。

### 5. Agent 基盤（`~/.agents` と `~/brain`）
SSH が通ってから clone する（どちらも非公開）。
```bash
git clone git@github.com:kouichiishikawa/agents.git ~/.agents
git clone git@github.com:kouichiishikawa/brain.git ~/brain
```
- 自分で作った launchd（`~/Library/LaunchAgents/com.kouichiishikawa.*`）・Claude Code のフック・スキルは dotfiles に入れない。`~/.agents` の README の手順で入れ直す
- MCP サーバーのトークンは 1Password から入れ直す。値はこのリポジトリにも会話にも書き写さない

### 6. 手で入れ直すもの
git の外にあるデータと、Brewfile に無いアプリの一覧は [docs/manual-migration.md](docs/manual-migration.md)（DEV-201 で作成予定）。

### 7. 確かめる
```bash
./test.sh
```
新しいシェルを開いてから実行する（`exec zsh -l`）。リンク・主要なツール（brew・mise・node・uv・python3・starship・gitleaks・delta・1Password の op-ssh-sign）・`brew bundle check`・シェルの起動時間（5 回の中央値が 0.3 秒以下）・`ssh -T git@github.com`・git の署名の設定・`core.hooksPath` を見て、1 つでも失敗すれば終了コード 1 になる。

## ふだんの使い方

```bash
./install.sh --dry-run      # いまの Mac と dotfiles の違いを一覧で見る
./install.sh --links-only   # リンクだけ作る（Homebrew・mise・uv・拡張機能・macOS の設定はしない）
./rollback.sh               # 退避先を選んで、install.sh が作ったリンクを外し、退避したものを戻す
./rollback.sh ~/.dotfiles_backup/20261029_120000   # 退避先を指定して戻す
./macos/defaults.sh         # macOS の設定だけ入れる
brew bundle check --verbose --file=Brewfile         # Brewfile にあって入っていないものを見る
```

- `rollback.sh` が戻すのは、`install.sh` が `<退避先>/links.txt` に記録したリンクと、そのときに退避したものだけ
- 設定を変えるときは、このリポジトリのファイルを直す（ホームにあるのはリンク）。Brewfile に足すときは `brew bundle dump` の結果から必要なものだけを足す
- ツールを足したら `test.sh` にも足す

## 含まれるもの
```
.
├── .zshrc / .zprofile        # zsh（mise・starship・fzf・zoxide・atuin・zsh のプラグイン）
├── .gitconfig                # git（delta・1Password の SSH 署名。user と署名の鍵は ~/.gitconfig.local）
├── .ssh/config               # SSH（1Password の SSH エージェントを使う。鍵のファイルは置かない）
├── .config/
│   ├── starship.toml         # プロンプト
│   ├── ghostty/config        # ターミナル（Ghostty）
│   ├── git/ignore            # git の全体の ignore
│   ├── mise/config.toml      # mise で入れるツール（Node の LTS）
│   └── cmux/cmux.json        # cmux の表示とショートカット
├── Brewfile                  # Homebrew の formula・cask と App Store のアプリ
├── macos/defaults.sh         # macOS の設定（defaults write）
├── editors/                  # VS Code（EDITOR は code）と Cursor の設定・キー割り当て・拡張機能の一覧
├── .githooks/pre-commit      # gitleaks による秘密情報の検査
├── archive/                  # 使わなくなった古いファイルの退避先
├── install.sh                # 新しい Mac を dotfiles の状態にする
├── rollback.sh               # install.sh のリンクと退避を戻す
└── test.sh                   # この Mac が dotfiles の状態かを確かめる
```

## よく使うエイリアス
```bash
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
