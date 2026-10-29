#!/bin/bash
# 新しい Mac を dotfiles の状態にする。何度実行しても同じ結果になる（入っているものは触らない）
#
# 使い方: ./install.sh              すべて行う
#         ./install.sh --dry-run    何をするかを一覧で出すだけで、何も変えない
#         ./install.sh --links-only リンクだけ作る（Homebrew・mise・uv・拡張機能・macOS の設定はしない）

set -Eeu

# スクリプトの場所を基準にする（どのフォルダから実行しても同じ結果にする）
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ホームにリンクするファイル（ここに書いたものだけをリンクする。rollback.sh・test.sh と揃える）
LINK_FILES=(.zshrc .zprofile .gitconfig .config/starship.toml .config/ghostty/config .config/git/ignore .config/mise/config.toml)
PYTHON_VERSION=3.12
OP_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

DRY_RUN=false
LINKS_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --links-only) LINKS_ONLY=true ;;
        -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "不明な引数: ${arg}（--help で使い方を表示）" >&2; exit 1 ;;
    esac
done

# 退避先は、退避するものが出たときに初めて作る（2 回目の実行で空のフォルダを増やさない）
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
CREATED=0
LINKED=0
BACKED_UP=0
TODO=()

ESC=$(printf '\033')
log()  { echo "${ESC}[32m==>${ESC}[0m ${ESC}[1m$1${ESC}[0m"; }
info() { echo "${ESC}[34m  -${ESC}[0m $1"; }
warn() { echo "${ESC}[33m  !${ESC}[0m $1"; }
plan() { echo "${ESC}[35m  +${ESC}[0m $1"; }
has()  { command -v "$1" >/dev/null 2>&1; }
todo() { TODO+=("$1"); }

# いま行っている変更（失敗したときに出す）
STEP=""
on_error() {
    echo "${ESC}[31m==>${ESC}[0m 失敗しました: ${STEP:-$1}" >&2
    if [ -f "$BACKUP_DIR/links.txt" ]; then
        echo "    ここまでのリンクと退避は ./rollback.sh $BACKUP_DIR で戻せます" >&2
    fi
}
trap 'on_error "$BASH_COMMAND"' ERR

# 変更を 1 つ行う。--dry-run のときは、何をするかを出すだけにする
# 使い方: change <数える欄 CREATED|LINKED|BACKED_UP> <説明> <コマンド...>
change() {
    local counter=$1 desc=$2
    shift 2
    plan "$desc"
    STEP=$desc
    eval "$counter=\$((\$$counter + 1))"
    if [ "$DRY_RUN" = false ]; then
        "$@"
    fi
}

backup() {
    local rel=$1
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$HOME/$rel" "$BACKUP_DIR/$rel"
}

make_link() {
    local src=$1 rel=$2
    mkdir -p "$(dirname "$HOME/$rel")"
    ln -s "$src" "$HOME/$rel"
    # rollback.sh が、このときに作ったリンクだけを外せるように残す
    mkdir -p "$BACKUP_DIR"
    echo "$rel" >> "$BACKUP_DIR/links.txt"
}

# $HOME/<rel> を <src> へのリンクにする。正しいリンクなら何もしない。別のものがあれば退避する
link() {
    local src=$1 rel=$2
    if [ -L "$HOME/$rel" ] && [ "$(readlink "$HOME/$rel")" = "$src" ]; then
        return
    fi
    if [ -e "$HOME/$rel" ] || [ -L "$HOME/$rel" ]; then
        change BACKED_UP "退避: ~/$rel → $BACKUP_DIR/$rel" backup "$rel"
    fi
    change LINKED "リンク: ~/$rel → $src" make_link "$src" "$rel"
}

setup_xcode_clt() {
    log "Xcode Command Line Tools"
    if xcode-select -p >/dev/null 2>&1; then
        return
    fi
    change CREATED "Xcode Command Line Tools を入れる（画面の案内に従い、終わったらもう一度 ./install.sh）" xcode-select --install
    if [ "$DRY_RUN" = false ]; then
        exit 0
    fi
}

install_homebrew() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

setup_homebrew() {
    log "Homebrew"
    if ! has brew && [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if has brew; then
        return
    fi
    change CREATED "Homebrew を入れる" install_homebrew
    if [ "$DRY_RUN" = false ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# SSH の鍵とコミットの署名に要るので、brew bundle より先に入れる（Brewfile には入れていない）
setup_1password() {
    log "1Password"
    if [ ! -d /Applications/1Password.app ]; then
        change CREATED "1Password のデスクトップアプリを入れる" brew install --cask 1password
    fi
    if [ ! -S "$OP_AGENT_SOCK" ]; then
        todo "1Password にサインインし、設定 > 開発者 で「SSH エージェントを使用」を有効にする"
    fi
}

setup_brew_bundle() {
    log "brew bundle（Brewfile）"
    if ! has brew; then
        plan "brew bundle --file=Brewfile（Homebrew を入れたあと）"
        return
    fi
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
        return
    fi
    if [ "$DRY_RUN" = true ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --file="$DOTFILES_DIR/Brewfile" 2>&1 | sed 's/^/    /' || true
    fi
    change CREATED "brew bundle --file=Brewfile（足りないものを入れる。App Store は先にサインインしておく）" \
        brew bundle --file="$DOTFILES_DIR/Brewfile"
}

setup_links() {
    log "リンク"
    local dotfile
    for dotfile in "${LINK_FILES[@]}"; do
        link "$DOTFILES_DIR/$dotfile" "$dotfile"
    done

    # SSH（鍵は 1Password の SSH エージェントから使う）
    if [ ! -d "$HOME/.ssh" ]; then
        change CREATED "作る: ~/.ssh（700）" mkdir -m 700 "$HOME/.ssh"
    elif [ "$(stat -f %OLp "$HOME/.ssh")" != 700 ]; then
        change CREATED "権限: ~/.ssh を 700 にする" chmod 700 "$HOME/.ssh"
    fi
    link "$DOTFILES_DIR/.ssh/config" .ssh/config

    # エディタ（入っているものだけ）
    local app dir name key
    for app in "Visual Studio Code:Code:vscode" "Cursor:Cursor:cursor"; do
        IFS=: read -r name dir key <<< "$app"
        [ -d "/Applications/$name.app" ] || continue
        link "$DOTFILES_DIR/editors/settings/$key.json" "Library/Application Support/$dir/User/settings.json"
        link "$DOTFILES_DIR/editors/keybindings/$key.json" "Library/Application Support/$dir/User/keybindings.json"
    done
}

# editors/extensions/<key>.txt のうち、まだ入っていない拡張機能だけを入れる
setup_editor_extensions() {
    log "エディタの拡張機能"
    local pair cli key installed ext
    for pair in "code:vscode" "cursor:cursor"; do
        IFS=: read -r cli key <<< "$pair"
        if ! has "$cli"; then
            continue
        fi
        installed=$("$cli" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
        while IFS= read -r ext || [ -n "$ext" ]; do
            [ -n "$ext" ] || continue
            if grep -qxF "$(echo "$ext" | tr '[:upper:]' '[:lower:]')" <<< "$installed"; then
                continue
            fi
            plan "$cli に入れる: $ext"
            if [ "$DRY_RUN" = true ]; then
                CREATED=$((CREATED + 1))
            elif "$cli" --install-extension "$ext" --force >/dev/null 2>&1; then
                CREATED=$((CREATED + 1))
            else
                # Marketplace から消えたものがあっても、ほかの手順は止めない（数には入れない）
                warn "入れられませんでした: ${ext}（editors/extensions/$key.txt から外すか、手で入れる）"
                todo "$cli の拡張機能 $ext を入れられなかった（editors/extensions/$key.txt を見直す）"
            fi
        done < "$DOTFILES_DIR/editors/extensions/$key.txt"
    done
}

setup_runtimes() {
    log "mise（Node）と uv（Python ${PYTHON_VERSION}）"
    if has mise; then
        # 調べられなかったとき（設定が信頼されていないなど）も入れる。mise install は設定を信頼してから入れる
        local missing
        # HOME で動かす（実行したフォルダのプロジェクトの mise の設定を拾わない）
        if ! missing=$(mise ls --missing -C "$HOME" 2>&1) || [ -n "$missing" ]; then
            change CREATED "mise install（~/.config/mise/config.toml のツール）" mise install -C "$HOME"
        fi
    else
        plan "mise install（brew bundle で mise を入れたあと）"
    fi
    if has uv; then
        if ! readlink "$HOME/.local/bin/python3" 2>/dev/null | grep -q "uv/python/cpython-$PYTHON_VERSION"; then
            change CREATED "uv python install $PYTHON_VERSION --default（~/.local/bin/python3）" \
                uv python install "$PYTHON_VERSION" --default
        fi
    else
        plan "uv python install $PYTHON_VERSION --default（brew bundle で uv を入れたあと）"
    fi
}

# コミット前に gitleaks で秘密情報を検査する
setup_git_hooks() {
    log "git の hook（gitleaks）"
    if [ "$(git -C "$DOTFILES_DIR" config core.hooksPath || true)" != .githooks ]; then
        change CREATED "git config core.hooksPath .githooks" git -C "$DOTFILES_DIR" config core.hooksPath .githooks
    fi
}

# 確認してから入れる（入れると Dock・Finder が再起動する）。--dry-run・確認できないときは入れない
setup_macos_defaults() {
    log "macOS の設定（macos/defaults.sh）"
    if [ "$DRY_RUN" = true ]; then
        plan "（実行時に確認）./macos/defaults.sh"
        return
    fi
    local answer=""
    printf "  macOS の設定（Dock・Finder・キーボード・トラックパッド）を入れますか？ (y/N): "
    read -r answer || true
    case "$answer" in
        [yY]|[yY][eE][sS]) "$DOTFILES_DIR/macos/defaults.sh"; info "macOS の設定を入れました" ;;
        *) info "入れませんでした（あとで ./macos/defaults.sh で入れられます）" ;;
    esac
}

# 機械では決められない残りの作業を集める（~ は表示用の文字なので展開しない）
# shellcheck disable=SC2088
collect_todo() {
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        todo "~/.gitconfig.local に user.name・user.email・user.signingkey を書く（README の「Git の名前と署名」）"
    fi
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        todo "ssh -T git@github.com が通ることを確かめる（1Password に SSH 鍵を入れ、GitHub に公開鍵を登録する）"
    fi
    [ -d "$HOME/.agents" ] || todo "~/.agents を clone して、その手順で launchd とフックを入れ直す（README の「Agent 基盤」）"
    [ -d "$HOME/brain" ] || todo "~/brain を clone する（README の「Agent 基盤」）"
    todo "MCP のトークンを 1Password から入れ直す（README の「Agent 基盤」。値は書き写さない）"
    todo "git の外のデータと手で入れ直すアプリ（docs/manual-migration.md）"
}

main() {
    if [ "$DRY_RUN" = true ]; then
        log "--dry-run: 何も変えずに、実行したら行うことを「+」で出します"
    fi
    if [ "$LINKS_ONLY" = false ]; then
        setup_xcode_clt
        setup_homebrew
        setup_1password
        setup_brew_bundle
    fi
    setup_links
    if [ "$LINKS_ONLY" = false ]; then
        setup_editor_extensions
        setup_runtimes
        setup_git_hooks
        setup_macos_defaults
    fi
    collect_todo

    echo
    log "結果: 作る・入れる $CREATED / リンク $LINKED / 退避 $BACKED_UP"
    if [ "$BACKED_UP" -gt 0 ] && [ "$DRY_RUN" = false ]; then
        info "退避先: ${BACKUP_DIR}（戻すときは ./rollback.sh ${BACKUP_DIR}）"
    fi
    echo
    log "人がやること"
    local item
    for item in "${TODO[@]}"; do
        info "$item"
    done
    if [ "$DRY_RUN" = false ]; then
        info "新しいシェルを開く（exec zsh -l）"
    fi
}

main
