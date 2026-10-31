#!/bin/bash
# macos/default-apps.txt の拡張子を、Finder でダブルクリックしたときに VS Code で開くようにする（duti を使う）
# 何度実行しても同じ結果になる（VS Code になっているものは触らない）
#
# 使い方: ./macos/default-apps.sh            VS Code になっていないものを VS Code にする
#         ./macos/default-apps.sh --dry-run  変えるものを出すだけで、何も変えない
#         ./macos/default-apps.sh --check    VS Code になっていないものを出し、1 つでもあれば終了コード 1

set -euo pipefail

BUNDLE_ID=com.microsoft.VSCode
LIST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/default-apps.txt"

MODE=apply
case "${1:-}" in
    "") ;;
    --dry-run) MODE=dry-run ;;
    --check) MODE=check ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "不明な引数: ${1}（--help で使い方を表示）" >&2; exit 1 ;;
esac

if ! command -v duti >/dev/null 2>&1; then
    echo "duti が無い（brew bundle --file=Brewfile で入れる）" >&2
    exit 1
fi
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    echo "VS Code が無い（brew bundle --file=Brewfile で入れる）" >&2
    exit 1
fi

# duti -x は 3 行目にバンドル ID を出す。開くアプリが無いときは何も出さずに失敗する
handler() { duti -x "$1" 2>/dev/null | sed -n 3p || true; }

wrong=0
while IFS= read -r ext || [ -n "$ext" ]; do
    case "$ext" in ''|'#'*) continue ;; esac
    current=$(handler "$ext")
    if [ "$current" = "$BUNDLE_ID" ]; then
        continue
    fi
    case "$MODE" in
        check) echo ".$ext: ${current:-開くアプリが無い}"; wrong=$((wrong + 1)) ;;
        dry-run) echo "+ .$ext: ${current:-開くアプリが無い} → $BUNDLE_ID" ;;
        apply)
            echo "+ .$ext: ${current:-開くアプリが無い} → $BUNDLE_ID"
            # duti は変わらなくても 0 を返すことがあるので、読み直して確かめる
            duti -s "$BUNDLE_ID" ".$ext" all 2>&1 | sed 's/^/    /' || true
            if [ "$(handler "$ext")" != "$BUNDLE_ID" ]; then
                echo "    ! .$ext が VS Code にならなかった（Finder で「情報を見る」→「このアプリケーションで開く」→「すべてを変更」）" >&2
                wrong=$((wrong + 1))
            fi
            ;;
    esac
done < "$LIST"

if [ "$wrong" -gt 0 ]; then
    echo "VS Code になっていない拡張子: $wrong 個" >&2
    exit 1
fi
