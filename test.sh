#!/bin/bash
# shellcheck disable=SC2088  # ~ は表示用の文字なので展開しない
# この Mac が dotfiles の状態になっているかを確かめる。1 つでも失敗すれば終了コード 1
#
# 使い方: ./test.sh
#         DOTFILES_DIR=~/dotfiles ./test.sh   リンク先の dotfiles を指定する（既定はこのスクリプトの場所）

set -u

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
DOTFILES_DIR=${DOTFILES_DIR%/}
# install.sh の LINK_FILES と揃える
LINK_FILES=(.zshrc .zprofile .gitconfig .config/starship.toml .config/ghostty/config .config/git/ignore .config/mise/config.toml)
PYTHON_VERSION=3.12
# シェルの起動時間の中央値の上限（秒）
STARTUP_LIMIT=0.3
OP_SSH_SIGN=/Applications/1Password.app/Contents/MacOS/op-ssh-sign

ESC=$(printf '\033')
PASSED=0
FAILED=0
pass()    { echo "${ESC}[32m✓${ESC}[0m $1"; PASSED=$((PASSED + 1)); }
fail()    { echo "${ESC}[31m✗${ESC}[0m $1"; FAILED=$((FAILED + 1)); }
section() { echo; echo "${ESC}[1m$1${ESC}[0m"; }

check_link() {
    local src=$1 rel=$2
    if [ -L "$HOME/$rel" ] && [ "$(readlink "$HOME/$rel")" = "$src" ]; then
        pass "~/$rel → $src"
    else
        fail "~/$rel が $src へのリンクではない（$(readlink "$HOME/$rel" 2>/dev/null || echo リンクではない)）"
    fi
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        pass "$1: $(command -v "$1")"
    else
        fail "$1 が見つからない"
    fi
}

section "リンク（${DOTFILES_DIR}）"
for dotfile in "${LINK_FILES[@]}"; do
    check_link "$DOTFILES_DIR/$dotfile" "$dotfile"
done
check_link "$DOTFILES_DIR/.ssh/config" .ssh/config
for app in "Visual Studio Code:Code:vscode" "Cursor:Cursor:cursor"; do
    IFS=: read -r name dir key <<< "$app"
    [ -d "/Applications/$name.app" ] || continue
    check_link "$DOTFILES_DIR/editors/settings/$key.json" "Library/Application Support/$dir/User/settings.json"
    check_link "$DOTFILES_DIR/editors/keybindings/$key.json" "Library/Application Support/$dir/User/keybindings.json"
done
if [ "$(stat -f %OLp "$HOME/.ssh" 2>/dev/null)" = 700 ]; then
    pass "~/.ssh の権限が 700"
else
    fail "~/.ssh の権限が 700 ではない"
fi

section "ツール"
for cmd in brew mise uv starship gitleaks delta; do
    check_command "$cmd"
done
if node_path=$(mise which node 2>/dev/null); then
    pass "node（mise）: $node_path $("$node_path" --version)"
else
    fail "mise の node が無い（mise install）"
fi
if python3 --version 2>&1 | grep -q "^Python $PYTHON_VERSION\."; then
    pass "python3: $(command -v python3) $(python3 --version 2>&1)"
else
    fail "python3 が $PYTHON_VERSION ではない（$(command -v python3) $(python3 --version 2>&1)）"
fi
if [ -x "$OP_SSH_SIGN" ]; then
    pass "1Password の op-ssh-sign: $OP_SSH_SIGN"
else
    fail "1Password の op-ssh-sign が無い（1Password のデスクトップアプリを入れる）"
fi
# brew の外で入れたアプリ（この Mac の手で入れたもの）は、cask の .app、cask が触る /Applications/ の下の
# パス（pkg のアプリや delete・実行ファイル）、pkg のレシートのどれかが手元にあれば入っているとみなし、
# brew bundle check から外す（新しい Mac では brew bundle が入れるので、ここでは外れない）
manual_casks() {
    local missing
    missing=$(comm -23 <(brew bundle list --cask --file="$DOTFILES_DIR/Brewfile" 2>/dev/null | sed 's|.*/||' | sort) \
                       <(brew list --cask -1 2>/dev/null | sort))
    [ -n "$missing" ] || return 0
    # shellcheck disable=SC2046,SC2086  # cask の名前とレシートの ID は空白を含まない
    brew info --cask --json=v2 $missing 2>/dev/null | /usr/bin/osascript -l JavaScript -e '
        ObjC.import("Foundation");
        const exists = p => $.NSFileManager.defaultManager.fileExistsAtPath(p);
        // 文字列をすべて取り出す（zap は消すときだけの場所なので見ない）
        const strings = v => typeof v === "string" ? [v] : v && typeof v === "object"
            ? Object.entries(v).flatMap(([k, x]) => k === "zap" ? [] : strings(x)) : [];
        function run(receipts) {
            const input = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
            const casks = JSON.parse($.NSString.alloc.initWithDataEncoding(input, 4).js).casks;
            return casks.filter(c => c.artifacts.some(a =>
                (a.app || []).some(x => exists("/Applications/" + (x.target || x).split("/").pop())) ||
                strings(a).some(s => s.startsWith("/Applications/") && exists(s.split("/").slice(0, 3).join("/"))) ||
                (a.uninstall || []).some(u => [].concat(u.pkgutil || []).some(id => receipts.includes(id)))
            )).map(c => c.token).join(" ");
        }' $(pkgutil --pkgs) 2>/dev/null
}
skip=$(manual_casks)
if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_BUNDLE_CASK_SKIP="$skip" brew bundle check --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
    pass "brew bundle check（Brewfile のものがすべて入っている。brew の外で入っている cask: $(echo "$skip" | wc -w | tr -d ' ') 個）"
else
    fail "brew bundle check が通らない（brew bundle check --verbose --file=Brewfile で足りないものを見る）"
fi

section "シェルの起動時間（zsh -i -c exit を 5 回）"
times=$(for _ in 1 2 3 4 5; do
    perl -MTime::HiRes=time -e '$t = time; system("zsh", "-i", "-c", "exit"); printf "%.3f\n", time - $t' 2>/dev/null
done | sort -n)
median=$(echo "$times" | sed -n 3p)
if [ -n "$median" ] && awk -v m="$median" -v l="$STARTUP_LIMIT" 'BEGIN { exit !(m <= l) }'; then
    pass "中央値 ${median} 秒（上限 ${STARTUP_LIMIT} 秒）"
else
    fail "中央値 ${median:-測れない} 秒（上限 ${STARTUP_LIMIT} 秒）: $(echo "$times" | tr '\n' ' ')"
fi

section "git と SSH"
if ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    pass "ssh -T git@github.com が通る"
else
    fail "ssh -T git@github.com が通らない（1Password の SSH エージェントと GitHub の公開鍵を確かめる）"
fi
check_git() {
    local key=$1 want=$2 got
    got=$(git config --global --includes --get "$key" 2>/dev/null)
    if [ "$got" = "$want" ]; then
        pass "git $key = $want"
    else
        fail "git $key が $want ではない（${got:-未設定}）"
    fi
}
check_git commit.gpgsign true
check_git gpg.format ssh
check_git gpg.ssh.program "$OP_SSH_SIGN"
# 名前・メール・署名の鍵は ~/.gitconfig.local にある（値は出さない）
for key in user.name user.email user.signingkey; do
    if [ -n "$(git config --global --includes --get "$key" 2>/dev/null)" ]; then
        pass "git $key がある（~/.gitconfig.local）"
    else
        fail "git $key が無い（~/.gitconfig.local に書く）"
    fi
done
if [ "$(git -C "$DOTFILES_DIR" config core.hooksPath)" = .githooks ]; then
    pass "dotfiles の core.hooksPath = .githooks（gitleaks）"
else
    fail "dotfiles の core.hooksPath が .githooks ではない"
fi

echo
echo "通った: $PASSED / 失敗: $FAILED"
if [ "$FAILED" -eq 0 ]; then
    echo "${ESC}[32mすべて通りました${ESC}[0m"
    exit 0
fi
echo "${ESC}[31m失敗があります${ESC}[0m"
exit 1
