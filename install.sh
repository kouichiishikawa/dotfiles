#!/bin/bash
# 新しい Mac を dotfiles の状態にする。何度実行しても同じ結果になる（入っているものは触らない）
#
# 使い方: ./install.sh              すべて行う
#         ./install.sh --dry-run    何をするかを一覧で出すだけで、何も変えない
#         ./install.sh --links-only リンクだけ作る（Homebrew・mise・uv・拡張機能・macOS の設定はしない）

set -Eeu

# スクリプトの場所を基準にする（どのフォルダから実行しても同じ結果にする）
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ホームにリンクするファイル（LINK_FILES。test.sh と同じ定義を読む）
# shellcheck source=lib/link-files.sh
source "$DOTFILES_DIR/lib/link-files.sh"
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

# 手順（main が順に呼ぶ）
# shellcheck source=lib/install-system.sh
source "$DOTFILES_DIR/lib/install-system.sh"
# shellcheck source=lib/install-links.sh
source "$DOTFILES_DIR/lib/install-links.sh"
# shellcheck source=lib/install-tools.sh
source "$DOTFILES_DIR/lib/install-tools.sh"

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
        setup_default_apps
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
