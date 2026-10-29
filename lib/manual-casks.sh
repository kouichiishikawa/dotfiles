# shellcheck shell=bash
# install.sh と test.sh が読む。brew bundle の check と install から外す cask を出す
#
# brew の外で入れたアプリ（この Mac で手で入れたもの）は、cask の .app、cask が触る /Applications/ の下の
# パス（pkg のアプリや delete・実行ファイル）、pkg のレシートのどれかが手元にあれば入っているとみなす。
# brew で入れ直すと既にあるアプリとぶつかって止まるので、HOMEBREW_BUNDLE_CASK_SKIP に渡して外す。
# 新しい Mac では何も見つからないので、何も外れない
#
# 使い方: HOMEBREW_BUNDLE_CASK_SKIP="$(manual_casks Brewfile || true)" brew bundle check --file=Brewfile
manual_casks() {
    local brewfile=$1 missing
    missing=$(comm -23 <(brew bundle list --cask --file="$brewfile" 2>/dev/null | sed 's|.*/||' | sort) \
                       <(brew list --cask -1 2>/dev/null | sort))
    [ -n "$missing" ] || return 0
    # shellcheck disable=SC2046,SC2086  # cask の名前とレシートの ID は空白を含まない
    brew info --cask --json=v2 $missing 2>/dev/null | /usr/bin/osascript -l JavaScript -e '
        ObjC.import("Foundation");
        const exists = p => $.NSFileManager.defaultManager.fileExistsAtPath(p);
        // 文字列をすべて取り出す（zap は消すときだけの場所なので見ない）
        const strings = v => typeof v === "string" ? [v] : v && typeof v === "object"
            ? Object.entries(v).flatMap(([k, x]) => k === "zap" ? [] : strings(x)) : [];
        // パスはワイルドカードの手前までを見る。まっさらな Mac にもある共有のフォルダは証拠にしない
        const shared = ["/Applications", "/Applications/Utilities"];
        const literal = s => { const p = s.split("/"), i = p.findIndex(x => /[*?[\]]/.test(x));
                               return (i < 0 ? p : p.slice(0, i)).join("/"); };
        const present = s => s.startsWith("/Applications/") && !shared.includes(literal(s)) && exists(literal(s));
        function run(receipts) {
            const input = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
            const casks = JSON.parse($.NSString.alloc.initWithDataEncoding(input, 4).js).casks;
            return casks.filter(c => c.artifacts.some(a =>
                (a.app || []).some(x => exists("/Applications/" + (x.target || x).split("/").pop())) ||
                strings(a).some(present) ||
                (a.uninstall || []).some(u => [].concat(u.pkgutil || []).some(id => receipts.includes(id)))
            )).map(c => c.token).join(" ");
        }' $(pkgutil --pkgs) 2>/dev/null
}
