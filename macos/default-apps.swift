// macos/default-apps.sh から呼ぶ。使い方: swift default-apps.swift <apply|dry-run|check> <一覧ファイル>
// duti ではなく NSWorkspace を使う。duti は動的な UTI（dyn.…）の拡張子と .toml を変えられない（2026-10-31 実測）
// macOS 27 では 1 件ごとに確認のダイアログが出て、押されるまで変わらない
import AppKit
import UniformTypeIdentifiers

let bundleID = "com.microsoft.VSCode"
let appURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
let mode = CommandLine.arguments[1]
let list = try! String(contentsOfFile: CommandLine.arguments[2], encoding: .utf8)
let exts = list.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
    .filter { !$0.isEmpty && !$0.hasPrefix("#") }

func handler(_ type: UTType) -> String? {
    NSWorkspace.shared.urlForApplication(toOpen: type).flatMap { Bundle(url: $0)?.bundleIdentifier }
}

let types = exts.map { ($0, UTType(filenameExtension: $0)!) }
let wrong = types.filter { handler($0.1) != bundleID }

if mode == "apply" && !wrong.isEmpty {
    print("確認のダイアログが \(wrong.count) 個出ます。VS Code の方を押してください（最大 5 分待つ）")
    var pending = wrong.count
    for (ext, type) in wrong {
        print("+ .\(ext): \(handler(type) ?? "開くアプリが無い") → \(bundleID)")
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpen: type) { error in
            if let error { print("    .\(ext): \(error.localizedDescription)") }
            pending -= 1
        }
    }
    let deadline = Date().addingTimeInterval(300)
    while pending > 0 && Date() < deadline {
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    }
}

// apply のあとは読み直して確かめる
var failed = 0
for (ext, type) in (mode == "apply" ? wrong : types) {
    let current = handler(type)
    if current == bundleID { continue }
    failed += 1
    switch mode {
    case "check": print(".\(ext): \(current ?? "開くアプリが無い")")
    case "dry-run": print("+ .\(ext): \(current ?? "開くアプリが無い") → \(bundleID)")
    default: FileHandle.standardError.write(".\(ext) が VS Code にならなかった（\(current ?? "開くアプリが無い")）\n".data(using: .utf8)!)
    }
}
if failed > 0 && mode != "dry-run" {
    FileHandle.standardError.write("VS Code になっていない拡張子: \(failed) 個\n".data(using: .utf8)!)
    exit(1)
}
