#!/bin/bash
# macos/default-apps.txt の拡張子を、Finder でダブルクリックしたときに VS Code で開くようにする
# 何度実行しても同じ結果になる（VS Code になっているものは触らない）。中身は default-apps.swift
# macOS 27 では変える 1 件ごとに確認のダイアログが出る。VS Code の方を押すまで変わらない
#
# 使い方: ./macos/default-apps.sh            VS Code になっていないものを VS Code にする
#         ./macos/default-apps.sh --dry-run  変えるものを出すだけで、何も変えない
#         ./macos/default-apps.sh --check    VS Code になっていないものを出し、1 つでもあれば終了コード 1

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE=apply
case "${1:-}" in
    "") ;;
    --dry-run) MODE=dry-run ;;
    --check) MODE=check ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "不明な引数: ${1}（--help で使い方を表示）" >&2; exit 1 ;;
esac

if ! command -v swift >/dev/null 2>&1; then
    echo "swift が無い（xcode-select --install で Command Line Tools を入れる）" >&2
    exit 1
fi
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    echo "VS Code が無い（brew bundle --file=Brewfile で入れる）" >&2
    exit 1
fi

exec swift "$DIR/default-apps.swift" "$MODE" "$DIR/default-apps.txt"
