#!/bin/bash

set -eu

# カラー定義
ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"

# テスト結果カウンタ
PASSED=0
FAILED=0

check_symlink() {
    local target=$1
    local link=$2
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        echo -e "${GREEN}✓${RESET} $link -> $target"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $link is not linked to $target"
        ((FAILED++))
        return 1
    fi
}

# テスト結果を記録する関数
test_pass() {
    echo -e "${GREEN}✓${RESET} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗${RESET} $1"
    ((FAILED++))
}

test_info() {
    echo -e "${GREEN}✓${RESET} $1"
}

# コマンド存在チェック
check_command() {
    local cmd=$1
    local desc=$2
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$desc is installed"
        return 0
    else
        test_fail "$desc is not installed"
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

# Python環境のテスト
echo "Testing Python environment..."

# pyenvのテスト
if check_command "pyenv" "pyenv"; then
    # Pythonバージョンの確認
    if pyenv versions | grep -q "3.11"; then
        test_pass "Python 3.11 is installed"
    else
        test_fail "Python 3.11 is not installed"
    fi
    
    # グローバルバージョンの確認
    local global_version=$(pyenv global)
    test_info "Global Python version: $global_version"
fi

# Poetryのテスト
if check_command "poetry" "Poetry"; then
    local poetry_version=$(poetry --version)
    test_info "$poetry_version"
fi

# Python設定ディレクトリのテスト
if [ -d "$HOME/.pip" ]; then
    test_pass ".pip directory exists"
else
    test_fail ".pip directory does not exist"
fi

if [ -d "$HOME/.jupyter" ]; then
    test_pass ".jupyter directory exists"
else
    test_fail ".jupyter directory does not exist"
fi

# 環境変数のテスト
echo "Testing environment variables..."

if [ -n "${PYENV_ROOT:-}" ]; then
    test_info "PYENV_ROOT is set: $PYENV_ROOT"
else
    test_fail "PYENV_ROOT is not set"
fi

if [ -n "${POETRY_VENV_IN_PROJECT:-}" ]; then
    test_pass "POETRY_VENV_IN_PROJECT is set"
else
    test_fail "POETRY_VENV_IN_PROJECT is not set"
fi

if [ -n "${PIP_REQUIRE_VIRTUALENV:-}" ]; then
    test_pass "PIP_REQUIRE_VIRTUALENV is set"
else
    test_fail "PIP_REQUIRE_VIRTUALENV is not set"
fi

# Homebrewのテスト
echo "Testing Homebrew..."
if check_command "brew" "Homebrew"; then
    local brew_version=$(brew --version | head -1)
    test_info "$brew_version"
fi

# テスト結果のサマリー
echo ""
echo "================================"
echo "Test Summary:"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"
echo "================================"

# 終了コード設定（CI/CD対応）
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}Some tests failed.${RESET}"
    exit 1
fi
