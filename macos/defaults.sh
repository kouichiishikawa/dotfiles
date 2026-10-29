#!/bin/bash
# macOS の設定を、2026-10-29 にこの Mac から `defaults read` で読み出した値に揃える
# 値は推測で足さない。変えるときは、いまの値を defaults read で確かめてから書き換える
#
# 使い方: ./macos/defaults.sh             設定して Dock・Finder・SystemUIServer を再起動する
#         ./macos/defaults.sh --no-restart  設定だけして再起動しない

set -euo pipefail

RESTART=true
if [ "${1:-}" = "--no-restart" ]; then
    RESTART=false
fi

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -float 61
defaults write com.apple.dock largesize -float 128
defaults write com.apple.dock orientation -string bottom
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock minimize-to-application -bool false
# 操作スペースを最近の使用状況で並べ替えない
defaults write com.apple.dock mru-spaces -bool false
# ホットコーナー（1 = 何もしない）
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-bl-corner -int 1
defaults write com.apple.dock wvous-br-corner -int 1

# Finder
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# カラム表示
defaults write com.apple.finder FXPreferredViewStyle -string clmv
# 検索は現在のフォルダから
defaults write com.apple.finder FXDefaultSearchScope -string SCcf
# 新しいウインドウはホームを開く
defaults write com.apple.finder NewWindowTarget -string PfHm
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# キーボード・入力
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool true
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool true
# F1〜F12 を標準のファンクションキーとして使う
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# トラックパッド（内蔵と Bluetooth の両方）
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false

# スクリーンショットはこの Mac で既定のまま使っているので書かない

if [ "$RESTART" = true ]; then
    killall Dock Finder SystemUIServer 2>/dev/null || true
fi

echo "macOS の設定を書き込みました。キーボードとトラックパッドは、ログインし直すと確実に反映されます"
