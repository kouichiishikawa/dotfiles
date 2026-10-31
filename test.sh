#!/bin/bash
# shellcheck disable=SC2088  # ~ は表示用の文字なので展開しない
# この Mac が dotfiles の状態になっているかを確かめる。1 つでも失敗すれば終了コード 1
#
# 使い方: ./test.sh
#         DOTFILES_DIR=~/dotfiles ./test.sh   リンク先の dotfiles を指定する（既定はこのスクリプトの場所。Brewfile は常にこのスクリプトの場所のもの）

set -u

# Brewfile と lib はこのスクリプトのあるリポジトリのものを使う（DOTFILES_DIR はリンク先を見るためだけ）
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$REPO_DIR}"
DOTFILES_DIR=${DOTFILES_DIR%/}
# install.sh の LINK_FILES と揃える
LINK_FILES=(.zshrc .zprofile .gitconfig .config/starship.toml .config/ghostty/config .config/git/ignore .config/mise/config.toml .config/cmux/cmux.json)
PYTHON_VERSION=3.12
# シェルの起動時間の最速値の上限（秒）。中央値は負荷しだいで上限を超えるので判定に使わない
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
# shellcheck source=lib/manual-casks.sh
source "$REPO_DIR/lib/manual-casks.sh"
skip=$(manual_casks "$REPO_DIR/Brewfile" || true)
# 更新待ちは「足りない」と数えない（--no-upgrade）
if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_BUNDLE_CASK_SKIP="$skip" brew bundle check --no-upgrade --file="$REPO_DIR/Brewfile" >/dev/null 2>&1; then
    pass "brew bundle check（Brewfile のものがすべて入っている。brew の外で入っている cask: $(echo "$skip" | wc -w | tr -d ' ') 個）"
else
    fail "brew bundle check が通らない（brew bundle check --no-upgrade --verbose --file=Brewfile で足りないものを見る）"
fi
# サードパーティ tap の formula・cask は、完全名＋trusted: true で書く（brew bundle がそれを信頼してから入れる）
untrusted=$(awk '
    /^tap "/ { split($0, q, "\""); t = tolower(q[2]); if (t !~ /^homebrew\//) taps[t] = 1 }
    /^(brew|cask) "[^"\/]+\/[^"\/]+\/[^"]+"/ {
        split($0, q, "\""); split(q[2], p, "/"); t = tolower(p[1] "/" p[2])
        if ($0 ~ /trusted: true/) ok[t] = 1; else bad = bad " " q[2]
    }
    END {
        for (t in taps) if (!(t in ok)) bad = bad " " t "（完全名＋trusted: true の行が無い）"
        print bad
    }' "$REPO_DIR/Brewfile")
if [ -z "${untrusted# }" ]; then
    pass "サードパーティ tap の formula・cask は完全名＋trusted: true"
else
    fail "trusted: true が無い:${untrusted}"
fi

section "シェルの起動時間（zsh -i -c exit を 5 回）"
times=$(for _ in 1 2 3 4 5; do
    perl -MTime::HiRes=time -e '$t = time; system("zsh", "-i", "-c", "exit"); printf "%.3f\n", time - $t' 2>/dev/null
done | sort -n)
fastest=$(echo "$times" | sed -n 1p)
median=$(echo "$times" | sed -n 3p)
loadavg=$(sysctl -n vm.loadavg | tr -d '{}' | xargs)
detail="中央値 ${median:-測れない} 秒、ロードアベレージ ${loadavg}"
if [ -n "$fastest" ] && awk -v m="$fastest" -v l="$STARTUP_LIMIT" 'BEGIN { exit !(m <= l) }'; then
    pass "最速値 ${fastest} 秒（上限 ${STARTUP_LIMIT} 秒。${detail}）"
else
    fail "最速値 ${fastest:-測れない} 秒（上限 ${STARTUP_LIMIT} 秒。${detail}）: $(echo "$times" | tr '\n' ' ')"
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
