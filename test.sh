#!/bin/bash

set -eu

# カラー定義
ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"

check_symlink() {
    local target=$1
    local link=$2
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        echo -e "${GREEN}✓${RESET} $link -> $target"
        return 0
    else
        echo -e "${RED}✗${RESET} $link is not linked to $target"
        return 1
    fi
}

# シンボリックリンクのテスト
echo "Testing symlinks..."
for dotfile in .??*; do
    [[ "$dotfile" == ".git" ]] && continue
    [[ "$dotfile" == ".gitignore" ]] && continue
    [[ "$dotfile" == ".DS_Store" ]] && continue
    [[ "$dotfile" == ".ssh" ]] && continue
    
    check_symlink "$HOME/dotfiles/$dotfile" "$HOME/$dotfile"
done

# SSHの設定テスト
if [ -f "$HOME/dotfiles/.ssh/config" ]; then
    check_symlink "$HOME/dotfiles/.ssh/config" "$HOME/.ssh/config"
    
    # パーミッションのチェック
    if [ "$(stat -f "%OLp" "$HOME/.ssh")" = "700" ]; then
        echo -e "${GREEN}✓${RESET} .ssh directory has correct permissions (700)"
    else
        echo -e "${RED}✗${RESET} .ssh directory has incorrect permissions"
    fi
    
    if [ -f "$HOME/.ssh/config" ] && [ "$(stat -f "%OLp" "$HOME/.ssh/config")" = "600" ]; then
        echo -e "${GREEN}✓${RESET} .ssh/config has correct permissions (600)"
    else
        echo -e "${RED}✗${RESET} .ssh/config has incorrect permissions or doesn't exist"
    fi
fi

# エディタ設定のテスト
echo "Testing editor configurations..."

# VSCode
if [ -d "/Applications/Visual Studio Code.app" ]; then
    echo "Testing VSCode settings..."
    check_symlink "$HOME/dotfiles/editors/settings/vscode.json" "$HOME/Library/Application Support/Code/User/settings.json"
    check_symlink "$HOME/dotfiles/editors/keybindings/vscode.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
fi

# Cursor
if [ -d "/Applications/Cursor.app" ]; then
    echo "Testing Cursor settings..."
    check_symlink "$HOME/dotfiles/editors/settings/cursor.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
    check_symlink "$HOME/dotfiles/editors/keybindings/cursor.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
fi
