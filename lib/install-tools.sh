# shellcheck shell=bash
# install.sh が読む。mise と uv・git の hook・ファイルを開くアプリ・macOS の設定・人がやることの手順
# install.sh の change・has・todo・log・info・plan と DRY_RUN・DOTFILES_DIR・PYTHON_VERSION・CREATED を使う

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

# 開発用のファイルを VS Code で開く。変えられなかった拡張子があってもほかの手順は止めない
setup_default_apps() {
    log "ファイルを開くアプリ（macos/default-apps.sh）"
    if "$DOTFILES_DIR/macos/default-apps.sh" --check >/dev/null 2>&1; then
        return
    fi
    plan "macos/default-apps.txt の拡張子を VS Code で開くようにする（1 件ごとに確認のダイアログが出る）"
    if [ "$DRY_RUN" = true ]; then
        CREATED=$((CREATED + 1))
    elif "$DOTFILES_DIR/macos/default-apps.sh"; then
        CREATED=$((CREATED + 1))
    else
        todo "VS Code で開くようにできなかった拡張子がある（./macos/default-apps.sh --check で見る）"
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
