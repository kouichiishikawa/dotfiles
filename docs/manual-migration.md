# 手で移すもののチェックリスト

新しい Mac は、まっさらな状態から dotfiles（`install.sh`・`Brewfile`）と `git clone` で入れ直す。
ここに載せるのは、**git にも Brewfile にも入っていないので、手で移さないと失われるもの**だけ。

- 2026-10-29 に古い Mac で測った結果。移行の直前に、末尾の「測り直す」のコマンドでもう一度測る
- 公開リポジトリなので、秘密の値・メールアドレス・社名・個人名・金額は書かない。秘密は場所と 1Password の有無だけを書く
- 「1Password」の列で「要確認」と書いた行は、移行の前に 1Password に入っていることを確かめ、入っていなければ入れてから ✅ にする

## 0. 当日の順番

1. 古い Mac で「3. 秘密の場所」を 1Password に入れたことを確かめる
2. 古い Mac で「5. 外付け SSD にコピーするもの」を rsync でコピーする
3. 古い Mac で「6. アプリの設定」のうち「書き出しが要る」ものを書き出す
4. 新しい Mac で README の手順（1Password → `install.sh` → `brew bundle`）を実行する
5. 新しい Mac で「1. Brewfile で入るアプリ」にサインインし、「2. 手で入れるもの」を入れる
6. 新しい Mac で外付け SSD から戻し、「4. 大きいデータ」の落とし直しを始める
7. 「8. 後片付け」を行う

## 1. Brewfile で入るアプリ（人がやること）

`install.sh` の `brew bundle` で入る（DEV-205 で Brewfile に足した）。入ったあとに人がやるのは、右の列のサインインと設定だけ。

| アプリ | cask | サインイン・ライセンス |
|---|---|---|
| Raycast | `raycast` | 要。設定は書き出しが要る（6 を見る） |
| Ghostty | `ghostty` | 不要（設定は dotfiles） |
| cmux | `cmux` | **要（アカウントでログインする）**。設定は dotfiles |
| Cursor / Visual Studio Code | `cursor` / `visual-studio-code` | 要（設定は各アプリの同期で戻る） |
| Claude / ChatGPT / Antigravity | `claude` / `chatgpt` / `antigravity` | 要 |
| Figma / Framer / Spline | `figma` / `framer` / `spline` | 要 |
| Notion / Notion Calendar / Linear / Obsidian | `notion` / `notion-calendar` / `linear` / `obsidian` | 要（Obsidian は保管庫を開き直す） |
| Google Chrome | `google-chrome` | 要（ブックマークなどは同期で戻る） |
| Discord / zoom | `discord` / `zoom` | 要 |
| Dropbox / Google Drive | `dropbox` / `google-drive` | 要（Google Drive は 2 アカウント） |
| GitHub Desktop / GitButler | `github` / `gitbutler` | 要 |
| Eagle | `ogdesign-eagle` | ライセンス要。移すライブラリは無い（4 を見る） |
| Screen Studio | `screen-studio` | ライセンス要 |
| Blender / AppCleaner / SF Symbols | `blender` / `appcleaner` / `sf-symbols` | 不要 |
| Google 日本語入力 | `google-japanese-ime` | 不要。ユーザー辞書は書き出しが要る（6 を見る） |
| Grok Bot | `grok-bot` | 要（DEV-209 で足した。手元のアプリと同じもの: アプリ名 `Grok Bot.app`、bundle ID `com.anysphere.sand` が cask の zap と一致） |
| Logi Options+ | `logi-options+` | 要（設定はアカウントのバックアップで戻る） |
| Elgato Stream Deck | `elgato-stream-deck` | 不要。プロファイルは書き出しが要る（6 を見る） |
| Philips Hue Sync | `philips-hue-sync` | 要（ブリッジとの再ペアリング） |
| Insta360 Link Controller | `insta360-link-controller` | 不要 |
| Focusrite Control 2 | `focusrite-control-2` | 不要 |
| Native Access | `native-access` | 要。音源は 4 を見る |
| Adobe Creative Cloud | `adobe-creative-cloud` | 要。Photoshop・Illustrator・Lightroom Classic・Acrobat はここから入れる |

1Password は Brewfile に入れない。SSH と署名に要るので、README の手順で最初に入れる（`install.sh` も `brew bundle` の前に入れる）。

## 2. 手で入れるもの（cask が無い・別の入手先）

| アプリ | 入手先 | メモ |
|---|---|---|
| Orca（`com.stablyai.orca`） | 公式サイト | cask の `orca` は名前が同じ別のソフト（plotly/orca）なので使わない |
| EVO（Audient） | Audient の公式サイト | オーディオインターフェースの制御 |
| FileZilla | 公式サイト | cask は廃止されている |
| VoiceOS | 公式サイト | 要サインイン |
| Photoshop・Illustrator・Lightroom Classic・Acrobat | Adobe Creative Cloud | 要サインイン |
| Native Instruments の音源・プラグイン | Native Access | 要サインイン。4 を見る |
| Google ドキュメント・スプレッドシート・スライド | Google Drive に付いてくる | 単体で入れる必要はない |

VS Code・Cursor の拡張機能のうち、マーケットプレイスに無いので `install.sh` が入れられないもの（DEV-205 で `editors/extensions/*.txt` から外した）。要るものだけ、古い Mac から VSIX を書き出すか、作者の配布元から入れる。

| エディタ | 拡張機能 |
|---|---|
| VS Code | `equinusocio.vsc-community-material-theme`（Marketplace に無い） |
| Cursor | `brapifra.phpserver` `equinusocio.vsc-community-material-theme` `equinusocio.vsc-material-theme` `equinusocio.vsc-material-theme-icons` `figma.figma-vscode-extension` `github.codespaces` `mosapride.zenkaku` `visualstudioexptteam.intellicode-api-usage-examples` `visualstudioexptteam.vscodeintellicode`（Open VSX に無い） |

入れ直さないもの: Arc と Dia（新しい Mac では使わない。2026-10-29 決定）、`Python 3.13`（python.org 版。`/usr/local/bin/python3` が指している。Python は uv で入れる。古い Mac の分はそのまま残す）、`/Applications/Hewlett-Packard`（リンク先が無い）、`~/Applications` のアンインストーラだけが残っているもの、`~/Applications/DDPM`（Dell のモニター管理のログと設定だけ）。

App Store のアプリ（`mas list` の 10 個）は全部 Brewfile にある。

## 3. 秘密の場所（git の外）

**中身はここに書かない。新しい Mac には、1Password から取り出すか、作り直す。**

| 何 | 場所 | 1Password | 移し方 |
|---|---|---|---|
| シェルの秘密の環境変数 | `~/.secrets.zsh` | 要確認 | 1Password から書き戻す |
| Claude Code の MCP 設定とトークン | `~/.claude.json` | 要確認 | MCP は入れ直して認証し直す。トークンは 1Password から |
| Git の名前・メールアドレス・署名の鍵 | `~/.gitconfig.local` | 要確認 | README の `git config --file ~/.gitconfig.local` で作り直す |
| Codex の認証と設定 | `~/.codex/auth.json`・`~/.codex/config.toml` | — | `codex login` でサインインし直す。config は Agent 基盤の移行で扱う |
| GitHub CLI | `~/.config/gh/hosts.yml` | — | `gh auth login` で作り直す |
| Google Cloud CLI | `~/.config/gcloud/` | — | `gcloud auth login` で作り直す |
| AWS の SSO | `~/.aws/sso/` | — | `aws sso login` で作り直す |
| Docker | `~/.docker/config.json` | — | Docker Desktop でサインインし直す |
| iOS アプリの秘密の設定 | 個人のリポジトリ 1 つの `Configs/Secrets.xcconfig` | 要確認 | 5 の rsync で移す |
| 各リポジトリの `.env*`（example などの見本を除く） | `~/Documents/01_projects` の下に 5 件 | 要確認 | 5 の rsync で移す |
| Cloudflare Workers の `.dev.vars` | `~/Documents/01_projects` の下に 1 件 | 要確認 | 5 の rsync で移す |
| 古い SSH の鍵 | `~/.ssh/id_ed25519`（2025-10 作成） | — | **移さない**（2026-10-29 決定）。SSH と署名は 1Password のエージェントを使う。8 を見る |

`~/.ssh/config` は dotfiles のリンクなので、手で移さなくてよい。`known_hosts` は接続し直せば作られる。

## 4. 大きいデータ

| 何 | 場所 | 大きさ | 移し方 |
|---|---|---|---|
| Logic・MainStage の音源 | `~/Music/Logic Pro Library.bundle`・`/Library/Application Support/Logic`・`/Library/Audio/Apple Loops` | 27G・30G・2.4G | **コピーしない。** MainStage（か Logic）の「サウンドライブラリ」から落とし直す（2026-10-29 決定） |
| Native Instruments の音源 | `/Users/Shared` の下（Kontakt・Maschine などのライブラリ）・`/Library/Application Support/Native Instruments` | 26G・2.0G | **コピーしない。** Native Access から落とし直す（2026-10-29 決定） |
| オーディオのプラグイン | `/Library/Audio/Plug-Ins` | 3.3G | 各メーカーのインストーラー（Native Access など）で入れ直す |
| MainStage のコンサート | `~/Music/MainStage`（`*.concert` が 3 個） | 5.4M | 5 の rsync で移す |
| 自分で作ったパッチ・音色 | `~/Music/Audio Music Apps` | 235M | 5 の rsync で移す |
| ミュージックのライブラリ | `~/Music/Music` | 1.0G | 5 の rsync で移す（iCloud ミュージックライブラリが有効なら同期で戻る） |
| 写真ライブラリ | `~/Pictures/Photos Library.photoslibrary` | 1.3G | iCloud 写真が有効なら同期で戻る。無効なら 5 の rsync で移す |
| Lightroom Classic のカタログ | `~/Pictures/Lightroom` | 31M | 5 の rsync で移す。**写真の元ファイルは移すものが無い**（2026-10-30 にカタログを読み取り専用で読んだ。登録された写真は 2 枚だけで、どちらも元ファイルがもう無い） |
| iMovie のライブラリ | `~/Movies/iMovieライブラリ.imovielibrary` | 2.0G | 5 の rsync で移す |
| CapCut・DaVinci Resolve の作業データ | `~/Movies/CapCut`・`~/Movies/DaVinci Resolve` | 337M・29M | 5 の rsync で移す |
| Eagle のライブラリ | 無い | — | **移さない。** 古い Mac では一度も起動しておらず、設定（`~/Library/Application Support/Eagle`）もライブラリ（`*.library`）も無い（2026-10-30 に確認）。新しい Mac で使うときに作る |

## 5. 外付け SSD にコピーするもの

**`~/Documents`・`~/Desktop` は iCloud にも同期されていない**（2026-10-29 に確認）。git のリポジトリは clone し直すので、コピーするのは git でないものと、git の外にある秘密のファイルだけにする（2026-10-29 決定）。

| 何 | 場所 | 大きさ |
|---|---|---|
| 書類 | `~/Documents`（git のリポジトリを除く） | 全体で 13G。うち `01_projects` が 8.3G で、git でないフォルダが 9 個ある |
| デスクトップ | `~/Desktop` | 2.3G |
| フォント | `~/Library/Fonts`（622 ファイル。TRIAL・商用のフォントを含む） | 892M |
| 音楽・写真・動画の作業データ | 4 で「5 の rsync で移す」とした行 | — |
| リポジトリの中の秘密のファイル | 3 の `.env*`・`.dev.vars`・`Secrets.xcconfig` | — |

古い Mac で SSD（例: `/Volumes/Migration`）をつないで実行する。`-n` を付けると、コピーせずに一覧だけを出す。

```bash
DEST=/Volumes/Migration/old-mac
mkdir -p "$DEST"   # GNU rsync は途中のフォルダを作らない（macOS 付属の openrsync は作る）

# 1) git のリポジトリの一覧（コピーから除く）
find ~/Documents -name node_modules -prune -o -type d -name .git -print \
  | sed -e "s|^$HOME/Documents/|/|" -e 's|/\.git$|/|' > /tmp/migration-repos.txt

# 2) 書類（git のリポジトリと node_modules を除く）・デスクトップ・フォント
rsync -a --exclude node_modules --exclude-from=/tmp/migration-repos.txt ~/Documents/ "$DEST/Documents/"
rsync -a ~/Desktop/ "$DEST/Desktop/"
rsync -a ~/Library/Fonts/ "$DEST/Fonts/"

# 3) 音楽・写真・動画の作業データ
rsync -a ~/Music/MainStage ~/Music/"Audio Music Apps" ~/Music/Music "$DEST/Music/"
rsync -a ~/Pictures/Lightroom "$DEST/Pictures/"
# iCloud 写真が無効なときだけ（写真アプリを閉じてから）
rsync -a ~/Pictures/"Photos Library.photoslibrary" "$DEST/Pictures/"
rsync -a ~/Movies/ "$DEST/Movies/"

# 4) リポジトリの中の秘密のファイル（場所を保ったまま）
cd ~/Documents && find 01_projects -name node_modules -prune -o -type f \
  \( -name '.env*' -o -name '.dev.vars' -o -name 'Secrets*.xcconfig' \) \
  ! -name '*.example' ! -name '*.sample' ! -name '*.template' -print > /tmp/migration-secrets.txt
rsync -a --files-from=/tmp/migration-secrets.txt ~/Documents/ "$DEST/Documents-secrets/"
```

新しい Mac では、リポジトリを clone し終えてから、同じ形で逆向きに `rsync -a "$DEST/…/" ~/…/` を実行する。秘密のファイルは `Documents-secrets/` から `~/Documents/` に戻す。SSD の秘密のファイルは、戻し終えたらゴミ箱に移す。

## 6. アプリの設定

| アプリ | 戻し方 |
|---|---|
| Raycast | **書き出しが要る**（Pro を契約していないのでクラウド同期が無い）。Settings → Advanced → Export で `.rayconfig` を書き出し、新しい Mac で Import する。自作のスクリプトは git のリポジトリにある |
| cmux | 設定（`~/.config/cmux/cmux.json`）は dotfiles のリンクで戻る。アカウントでのログインは手で行う |
| Google 日本語入力 | **書き出しが要る**。辞書ツールでユーザー辞書を書き出し、新しい Mac で読み込む |
| Elgato Stream Deck | **書き出しが要る**。設定のプロファイルを書き出す（または「バックアップ」） |
| 1Password | サインインで戻る。SSH エージェントを有効にする（README） |
| Magnet | App Store から入れ直す。ショートカットを変えていたら手で設定し直す |
| Slack・LINE・Messenger・Discord・zoom | サインインで戻る |
| Logi Options+ | サインインして、アカウントのバックアップから戻す |
| VS Code・Cursor | 各アプリの設定同期（Settings Sync）で戻る。同期を使っていなければ拡張の一覧を書き出す |
| Obsidian | 保管庫は iCloud（iCloud Drive の Obsidian フォルダ）と `~/brain`（git）にある。新しい Mac で保管庫を開き直す |
| Claude Code・Codex（`~/.claude`・`~/.codex`） | Agent 基盤の移行手順で扱う（このチェックリストの外）。`~/.agents`・`~/brain` は GitHub に remote がある |
| ブラウザ（Chrome） | サインインして同期で戻る。Arc と Dia は入れない |
| macOS の設定 | dotfiles の `macos/defaults.sh` |

## 7. その他

| 何 | 場所 | 移し方 |
|---|---|---|
| 自作の launchd（7 個） | `~/Library/LaunchAgents/com.kouichiishikawa.*` | plist の元は git にある（`~/.agents/skills/*/launchd/` と design-reference のリポジトリの `launchd/`）。入れ方は README の 5。`sprint-followup` は `~/.agents/skills/sprint/references/watchdog.md` の「followup の入れ方」 |
| ほかのアプリが入れた launchd | `~/Library/LaunchAgents`・`/Library/LaunchAgents`・`/Library/LaunchDaemons`（Adobe・Google・Dropbox・Logi・Zoom・Epson・Microsoft など） | アプリを入れ直せば作られる。手で移さない |
| ログインシェル以外のシェルの設定 | `~/.bash_profile` | DEV-202 で扱う |
| シェルの履歴 | `~/.zsh_history`（324K） | 要るなら 5 の rsync に足す |

## 8. 後片付け（切り替えが終わってから）

- [ ] GitHub の古い SSH 鍵（Main SSH Key）を外す（古い `~/.ssh/id_ed25519` は移していない）
- [ ] 外付け SSD の `Documents-secrets/` をゴミ箱に移す
- [ ] 新しい Mac で `brew bundle check --file=~/dotfiles/Brewfile` が通ることを確かめる

## 測り直す（移行の直前に古い Mac で実行する）

ここに載せた件数と大きさは、次のコマンドで測った。表と違っていたら、表を直してから移す。

```bash
# Brewfile に無いアプリ（App Store のものは mas list と比べる）
ls /Applications ~/Applications
grep -E '^(cask|mas)' ~/dotfiles/Brewfile
mas list
brew casks > /tmp/all-casks.txt   # cask の有無は grep -x '<名前>' /tmp/all-casks.txt で見る

# 秘密の場所（中身は開かない）
ls -la ~/.secrets.zsh ~/.claude.json ~/.gitconfig.local ~/.ssh ~/.codex/auth.json ~/.config/gh ~/.config/gcloud ~/.aws ~/.docker/config.json
find ~/Documents/01_projects -name node_modules -prune -o -name .git -prune -o -type f \
  \( -name '.env*' -o -name '.dev.vars*' -o -name 'Secrets*.xcconfig' -o -name '*.pem' -o -name '*.p12' -o -name '*.p8' \) -print \
  | awk -F/ '{print $NF}' | sort | uniq -c

# 大きいデータ
du -sh ~/Music/* ~/Pictures/* ~/Movies/* ~/Documents/* ~/Desktop ~/Library/Fonts
du -sh "/Library/Application Support/Logic" "/Library/Application Support/Native Instruments" /Users/Shared "/Library/Audio/Apple Loops" "/Library/Audio/Plug-Ins"
find ~/Music/MainStage -name '*.concert'
# Lightroom の元写真のフォルダ（Lightroom を閉じて、カタログのコピーを読む）
cp ~/Pictures/Lightroom/*-v13.lrcat /tmp/lr.lrcat
sqlite3 'file:/tmp/lr.lrcat?mode=ro&immutable=1' 'select absolutePath from AgLibraryRootFolder; select count(*) from Adobe_images;'
# Eagle のライブラリ（設定が無ければ使っていない）
ls ~/Library/Application\ Support/Eagle

# iCloud に同期されているか（0 なら同期されていない）
defaults read com.apple.finder FXICloudDriveDesktop
defaults read com.apple.finder FXICloudDriveDocuments

# git でないフォルダ（01_projects の 2 段目）
find ~/Documents/01_projects -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -exec test -e '{}/.git' ';' -exec du -sh '{}' ';'

# launchd
ls ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons
```
