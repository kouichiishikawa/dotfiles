#!/bin/bash

set -eu

# 関数定義
has() {
    type "$1" > /dev/null 2>&1
}

# 必要なツールのチェック
if ! has "git"; then
    echo "Error: git is required"
    exit 1
fi

# 定数定義
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# カラー定義
ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
BLUE="${ESC}[34m"

log() {
    echo -e "${GREEN}==>${RESET} ${BOLD}$1${RESET}"
}

error() {
    echo -e "${RED}==>${RESET} ${BOLD}$1${RESET}"
}

info() {
    echo -e "${BLUE}==>${RESET} ${BOLD}$1${RESET}"
}

# バックアップディレクトリの作成
mkdir -p "$BACKUP_DIR"
log "Created backup directory: $BACKUP_DIR"

# ドットファイルのシンボリックリンク作成
create_symlinks() {
    log "Creating symlinks..."
    for dotfile in .??*; do
        # 除外ファイル
        [[ "$dotfile" == ".git" ]] && continue
        [[ "$dotfile" == ".gitignore" ]] && continue
        [[ "$dotfile" == ".DS_Store" ]] && continue
        [[ "$dotfile" == ".Trash" ]] && continue

        # 既存ファイルのバックアップ
        if [ -e "$HOME/$dotfile" ]; then
            info "Backing up $dotfile"
            mv "$HOME/$dotfile" "$BACKUP_DIR/"
        fi

        # シンボリックリンクの作成
        info "Linking $dotfile"
        ln -snfv "$DOTFILES_DIR/$dotfile" "$HOME/$dotfile"
    done
}

# SSHの設定
setup_ssh() {
    log "Setting up SSH config..."
    if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        # 既存のSSH configをバックアップ
        if [ -f "$HOME/.ssh/config" ]; then
            info "Backing up existing SSH config"
            mv "$HOME/.ssh/config" "$BACKUP_DIR/"
        fi

        info "Linking SSH config"
        ln -snfv "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
    fi
}

# Homebrewがインストールされているか確認
setup_homebrew() {
    if ! has "brew"; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew is already installed"
    fi
}

# メイン処理
main() {
    log "Start setup..."
    
    # 既存のdotfilesディレクトリをチェック
    if [ -d "$DOTFILES_DIR" ]; then
        create_symlinks
        setup_ssh
        setup_homebrew
    else
        error "dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    log "Setup completed successfully!"
    info "Backup can be found in: $BACKUP_DIR"
}

main
