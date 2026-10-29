#!/bin/bash
# install.sh が作ったリンクを外し、退避したファイルを元の場所へ戻す
#
# 使い方: ./rollback.sh                 退避先を一覧から選ぶ（Enter で最新）
#         ./rollback.sh <退避先>         その退避先から戻す（例: ~/.dotfiles_backup/20261029_120000）
#         ./rollback.sh <退避先> --yes   確認せずに戻す
#
# install.sh は、作ったリンクを <退避先>/links.txt に、退避したものを <退避先>/<HOME からの相対パス> に残す。
# ここではその 2 つだけを見る（links.txt に無いものは触らない）

set -eu

BACKUP_BASE="$HOME/.dotfiles_backup"

ESC=$(printf '\033')
log()   { echo "${ESC}[32m==>${ESC}[0m ${ESC}[1m$1${ESC}[0m"; }
info()  { echo "${ESC}[34m  -${ESC}[0m $1"; }
warn()  { echo "${ESC}[33m  !${ESC}[0m $1"; }
error() { echo "${ESC}[31m==>${ESC}[0m ${ESC}[1m$1${ESC}[0m" >&2; }

# 退避先を一覧から選ぶ。一覧と質問は標準エラーに出し、標準出力には選んだパスだけを出す
# （$(...) で受け取るので、表示を標準出力に出すとパスに混ざる）
select_backup_directory() {
    local backups selection picked
    backups=$(ls -1t "$BACKUP_BASE" 2>/dev/null || true)
    if [ -z "$backups" ]; then
        error "退避先がありません: $BACKUP_BASE"
        return 1
    fi
    echo "退避先（新しい順）:" >&2
    echo "$backups" | nl -w2 -s') ' >&2
    printf "番号を選んでください（Enter で最新）: " >&2
    read -r selection || true
    selection=${selection:-1}
    if [[ "$selection" =~ ^[1-9][0-9]*$ ]]; then
        picked=$(echo "$backups" | sed -n "${selection}p")
    fi
    if [ -z "${picked:-}" ]; then
        error "選んだ番号がありません: $selection"
        return 1
    fi
    echo "$BACKUP_BASE/$picked"
}

main() {
    local backup_dir="" yes=false arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
            --yes) yes=true ;;
            *) backup_dir=$arg ;;
        esac
    done
    if [ -z "$backup_dir" ]; then
        backup_dir=$(select_backup_directory)
    fi
    backup_dir=${backup_dir%/}
    if [ ! -d "$backup_dir" ]; then
        error "退避先がありません: $backup_dir"
        exit 1
    fi
    if [ ! -f "$backup_dir/links.txt" ]; then
        error "$backup_dir/links.txt がありません（2026-10 より前の install.sh の退避先です）。中身を見て手で戻してください"
        exit 1
    fi

    log "戻す元: $backup_dir"
    if [ "$yes" = false ]; then
        local confirm=""
        printf "戻しますか？ (y/N): "
        read -r confirm || true
        case "$confirm" in
            [yY]|[yY][eE][sS]) ;;
            *) info "やめました"; exit 0 ;;
        esac
    fi

    local rel removed=0 restored=0
    while IFS= read -r rel || [ -n "$rel" ]; do
        [ -n "$rel" ] || continue
        # 自分が作ったリンクだけを外す（リンクでなくなっていたら、人が置いたものなので残す）
        if [ -L "$HOME/$rel" ]; then
            info "リンクを外す: ~/$rel"
            rm "$HOME/$rel"
            removed=$((removed + 1))
        elif [ -e "$HOME/$rel" ]; then
            warn "リンクではないので残します: ~/$rel"
            continue
        fi
        # -L も見る: 退避したのが相対リンクだと、移した先では解決できず -e が偽になる
        if [ -e "$backup_dir/$rel" ] || [ -L "$backup_dir/$rel" ]; then
            info "戻す: ~/$rel"
            mkdir -p "$(dirname "$HOME/$rel")"
            mv "$backup_dir/$rel" "$HOME/$rel"
            restored=$((restored + 1))
        fi
    done < "$backup_dir/links.txt"

    log "結果: リンクを外した $removed / 戻した $restored"
    info "退避先は残してあります: $backup_dir"
    info "新しいシェルを開いてください（exec zsh -l）"
}

main "$@"
