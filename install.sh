#!/bin/bash

set -eu

# エラーハンドリング
trap 'handle_error $? $LINENO' ERR

handle_error() {
    local exit_code=$1
    local line_number=$2
    error "Error occurred at line $line_number with exit code $exit_code"
    
    # ロールバックの実行
    if [ -f "$DOTFILES_DIR/rollback.sh" ]; then
        warn "Attempting to rollback changes..."
        if [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ]; then
            "$DOTFILES_DIR/rollback.sh" "$BACKUP_DIR"
        fi
    fi
    
    exit $exit_code
}

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
        [[ "$dotfile" == ".ssh" ]] && continue

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

# エディタの設定
setup_editors() {
    log "Setting up editor configurations..."
    
    # VSCode
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        info "Setting up VSCode..."
        mkdir -p "$HOME/Library/Application Support/Code/User"
        
        # バックアップ
        if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
            mv "$HOME/Library/Application Support/Code/User/settings.json" "$BACKUP_DIR/vscode_settings.json"
        fi
        if [ -f "$HOME/Library/Application Support/Code/User/keybindings.json" ]; then
            mv "$HOME/Library/Application Support/Code/User/keybindings.json" "$BACKUP_DIR/vscode_keybindings.json"
        fi
        
        # シンボリックリンク作成
        info "Linking VSCode settings"
        ln -snfv "$DOTFILES_DIR/editors/settings/vscode.json" "$HOME/Library/Application Support/Code/User/settings.json"
        ln -snfv "$DOTFILES_DIR/editors/keybindings/vscode.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

        # 拡張機能のインストール
        info "Installing VSCode extensions"
        while IFS= read -r extension || [ -n "$extension" ]; do
            code --install-extension "$extension"
        done < "$DOTFILES_DIR/editors/extensions/vscode.txt"
    fi
    
    # Cursor
    if [ -d "/Applications/Cursor.app" ]; then
        info "Setting up Cursor..."
        mkdir -p "$HOME/Library/Application Support/Cursor/User"
        
        # バックアップ
        if [ -f "$HOME/Library/Application Support/Cursor/User/settings.json" ]; then
            mv "$HOME/Library/Application Support/Cursor/User/settings.json" "$BACKUP_DIR/cursor_settings.json"
        fi
        if [ -f "$HOME/Library/Application Support/Cursor/User/keybindings.json" ]; then
            mv "$HOME/Library/Application Support/Cursor/User/keybindings.json" "$BACKUP_DIR/cursor_keybindings.json"
        fi
        
        # シンボリックリンク作成
        info "Linking Cursor settings"
        ln -snfv "$DOTFILES_DIR/editors/settings/cursor.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
        ln -snfv "$DOTFILES_DIR/editors/keybindings/cursor.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"

        # 拡張機能のインストール
        info "Installing Cursor extensions"
        while IFS= read -r extension || [ -n "$extension" ]; do
            cursor --install-extension "$extension"
        done < "$DOTFILES_DIR/editors/extensions/cursor.txt"
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

# Python環境のセットアップ
setup_python() {
    log "Setting up Python environment..."
    
    # pyenvのインストール
    if ! has "pyenv"; then
        info "Installing pyenv..."
        if has "brew"; then
            if ! brew install pyenv; then
                error "Failed to install pyenv"
                return 1
            fi
        else
            error "Homebrew is required to install pyenv"
            return 1
        fi
    else
        info "pyenv is already installed"
    fi
    
    # pyenvの初期化
    export PYENV_ROOT="$HOME/.pyenv" 
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    # pyenvが正しく初期化できるかチェック
    if ! eval "$(pyenv init -)"; then
        error "Failed to initialize pyenv"
        return 1
    fi
    
    # 最新安定版Pythonのインストール
    if ! pyenv versions | grep -q "3.11"; then
        info "Installing Python 3.11..."
        if ! pyenv install 3.11.9; then
            error "Failed to install Python 3.11.9"
            return 1
        fi
        if ! pyenv global 3.11.9; then
            error "Failed to set Python 3.11.9 as global"
            return 1
        fi
    else
        info "Python 3.11 is already installed"
    fi
    
    # Poetryのインストール
    if ! has "poetry"; then
        info "Installing Poetry..."
        if ! curl -sSL https://install.python-poetry.org | python3 -; then
            error "Failed to install Poetry"
            return 1
        fi
        export PATH="$HOME/.local/bin:$PATH"
        
        # Poetryが正しくインストールされたかチェック
        if ! command -v poetry >/dev/null 2>&1; then
            error "Poetry installation verification failed"
            return 1
        fi
    else
        info "Poetry is already installed"
    fi
    
    # pipの設定ディレクトリ作成
    if ! mkdir -p "$HOME/.pip"; then
        error "Failed to create .pip directory"
        return 1
    fi
    
    # Jupyter設定ディレクトリ作成
    if ! mkdir -p "$HOME/.jupyter"; then
        error "Failed to create .jupyter directory"
        return 1
    fi
    
    info "Python environment setup completed"
}

# メイン処理
main() {
    log "Start setup..."
    
    # 既存のdotfilesディレクトリをチェック
    if [ -d "$DOTFILES_DIR" ]; then
        create_symlinks
        setup_ssh
        setup_editors
        setup_homebrew
        setup_python
    else
        error "dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    log "Setup completed successfully!"
    info "Backup can be found in: $BACKUP_DIR"
    info "Please restart your shell or run: source ~/.zshrc"
}

main
