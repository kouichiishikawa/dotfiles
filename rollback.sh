#!/bin/bash

set -eu

# カラー定義
ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
BLUE="${ESC}[34m"
YELLOW="${ESC}[33m"

log() {
    echo -e "${GREEN}==>${RESET} ${BOLD}$1${RESET}"
}

error() {
    echo -e "${RED}==>${RESET} ${BOLD}$1${RESET}"
}

info() {
    echo -e "${BLUE}==>${RESET} ${BOLD}$1${RESET}"
}

warn() {
    echo -e "${YELLOW}==>${RESET} ${BOLD}$1${RESET}"
}

# バックアップディレクトリの検索
find_backup_directory() {
    local backup_base="$HOME/.dotfiles_backup"
    
    if [ ! -d "$backup_base" ]; then
        error "No backup directory found at $backup_base"
        exit 1
    fi
    
    # 最新のバックアップディレクトリを取得
    local latest_backup=$(ls -1t "$backup_base" | head -1)
    
    if [ -z "$latest_backup" ]; then
        error "No backup found in $backup_base"
        exit 1
    fi
    
    echo "$backup_base/$latest_backup"
}

# 特定のバックアップディレクトリを指定
select_backup_directory() {
    local backup_base="$HOME/.dotfiles_backup"
    
    if [ ! -d "$backup_base" ]; then
        error "No backup directory found at $backup_base"
        exit 1
    fi
    
    info "Available backups:"
    ls -1t "$backup_base" | nl -w2 -s') '
    
    echo -n "Select backup number (Enter for latest): "
    read -r selection
    
    if [ -z "$selection" ]; then
        find_backup_directory
    else
        local backup_dir=$(ls -1t "$backup_base" | sed -n "${selection}p")
        if [ -z "$backup_dir" ]; then
            error "Invalid selection"
            exit 1
        fi
        echo "$backup_base/$backup_dir"
    fi
}

# シンボリックリンクの削除
remove_symlinks() {
    log "Removing dotfiles symlinks..."
    
    for dotfile in .??*; do
        # 除外ファイル
        [[ "$dotfile" == ".git" ]] && continue
        [[ "$dotfile" == ".gitignore" ]] && continue
        [[ "$dotfile" == ".DS_Store" ]] && continue
        [[ "$dotfile" == ".Trash" ]] && continue
        [[ "$dotfile" == ".ssh" ]] && continue
        
        local target="$HOME/$dotfile"
        
        if [ -L "$target" ]; then
            info "Removing symlink: $dotfile"
            rm "$target"
        elif [ -e "$target" ]; then
            warn "File exists but is not a symlink: $dotfile"
        fi
    done
}

# エディタ設定のロールバック
rollback_editors() {
    log "Rolling back editor configurations..."
    
    # VSCode
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        info "Rolling back VSCode settings..."
        local vscode_dir="$HOME/Library/Application Support/Code/User"
        
        # シンボリックリンクを削除
        [ -L "$vscode_dir/settings.json" ] && rm "$vscode_dir/settings.json"
        [ -L "$vscode_dir/keybindings.json" ] && rm "$vscode_dir/keybindings.json"
        
        # バックアップから復元
        if [ -f "$1/vscode_settings.json" ]; then
            info "Restoring VSCode settings"
            mv "$1/vscode_settings.json" "$vscode_dir/settings.json"
        fi
        
        if [ -f "$1/vscode_keybindings.json" ]; then
            info "Restoring VSCode keybindings"
            mv "$1/vscode_keybindings.json" "$vscode_dir/keybindings.json"
        fi
    fi
    
    # Cursor
    if [ -d "/Applications/Cursor.app" ]; then
        info "Rolling back Cursor settings..."
        local cursor_dir="$HOME/Library/Application Support/Cursor/User"
        
        # シンボリックリンクを削除
        [ -L "$cursor_dir/settings.json" ] && rm "$cursor_dir/settings.json"
        [ -L "$cursor_dir/keybindings.json" ] && rm "$cursor_dir/keybindings.json"
        
        # バックアップから復元
        if [ -f "$1/cursor_settings.json" ]; then
            info "Restoring Cursor settings"
            mv "$1/cursor_settings.json" "$cursor_dir/settings.json"
        fi
        
        if [ -f "$1/cursor_keybindings.json" ]; then
            info "Restoring Cursor keybindings"
            mv "$1/cursor_keybindings.json" "$cursor_dir/keybindings.json"
        fi
    fi
}

# SSH設定のロールバック
rollback_ssh() {
    log "Rolling back SSH configuration..."
    
    if [ -L "$HOME/.ssh/config" ]; then
        info "Removing SSH config symlink"
        rm "$HOME/.ssh/config"
    fi
    
    if [ -f "$1/config" ]; then
        info "Restoring SSH config"
        mv "$1/config" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
    fi
}

# dotfilesの復元
restore_dotfiles() {
    local backup_dir="$1"
    
    log "Restoring dotfiles from: $backup_dir"
    
    # バックアップディレクトリ内のファイルを復元
    for backup_file in "$backup_dir"/.??*; do
        [ ! -e "$backup_file" ] && continue
        
        local filename=$(basename "$backup_file")
        local target="$HOME/$filename"
        
        info "Restoring $filename"
        mv "$backup_file" "$target"
    done
}

# メイン処理
main() {
    log "Starting dotfiles rollback..."
    
    # 引数でバックアップディレクトリが指定されている場合
    if [ $# -gt 0 ]; then
        local backup_dir="$1"
        if [ ! -d "$backup_dir" ]; then
            error "Backup directory not found: $backup_dir"
            exit 1
        fi
    else
        # インタラクティブにバックアップを選択
        local backup_dir=$(select_backup_directory)
    fi
    
    info "Using backup: $backup_dir"
    
    # 確認
    echo -n "Are you sure you want to rollback? (y/N): "
    read -r confirm
    case "$confirm" in
        [yY]|[yY][eE][sS])
            ;;
        *)
            info "Rollback cancelled"
            exit 0
            ;;
    esac
    
    # 現在のディレクトリを保存
    local current_dir=$(pwd)
    
    # dotfilesディレクトリに移動
    cd "$HOME/dotfiles" || {
        error "Failed to change to dotfiles directory"
        exit 1
    }
    
    # ロールバック実行
    remove_symlinks
    rollback_editors "$backup_dir"
    rollback_ssh "$backup_dir"
    restore_dotfiles "$backup_dir"
    
    # 元のディレクトリに戻る
    cd "$current_dir"
    
    # バックアップディレクトリを削除
    if [ -d "$backup_dir" ] && [ -z "$(ls -A "$backup_dir")" ]; then
        info "Removing empty backup directory"
        rmdir "$backup_dir"
    fi
    
    log "Rollback completed successfully!"
    info "Please restart your shell to apply changes"
}

# 使用方法の表示
show_usage() {
    echo "Usage: $0 [backup_directory]"
    echo "  backup_directory: Specific backup directory to restore from"
    echo "  If not specified, will show interactive selection"
}

# ヘルプオプション
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
esac

main "$@"