# shellcheck shell=bash
# install.sh が読む。ホームへのリンク（LINK_FILES・SSH・エディタの設定）とエディタの拡張機能の手順
# install.sh の link・change・has・todo・log・plan・warn と DRY_RUN・DOTFILES_DIR・LINK_FILES・CREATED を使う

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
