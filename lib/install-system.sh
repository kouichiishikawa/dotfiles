# shellcheck shell=bash
# install.sh が読む。Xcode Command Line Tools・Homebrew・1Password・brew bundle の手順
# install.sh の change・has・todo・log・plan と DRY_RUN・DOTFILES_DIR・OP_AGENT_SOCK を使う

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
    # brew の外で入れたアプリは入れ直さない（既にあるアプリとぶつかって止まるため）
    # shellcheck source=lib/manual-casks.sh
    source "$DOTFILES_DIR/lib/manual-casks.sh"
    HOMEBREW_BUNDLE_CASK_SKIP="$(manual_casks "$DOTFILES_DIR/Brewfile" || true)"
    export HOMEBREW_BUNDLE_CASK_SKIP
    # 更新待ちは「足りない」と数えない（--no-upgrade）
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
        return
    fi
    if [ "$DRY_RUN" = true ]; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --verbose --file="$DOTFILES_DIR/Brewfile" 2>&1 | sed 's/^/    /' || true
    fi
    change CREATED "brew bundle --file=Brewfile（足りないものを入れる。App Store は先にサインインしておく）" \
        brew bundle --file="$DOTFILES_DIR/Brewfile"
}
