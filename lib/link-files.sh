# shellcheck shell=bash
# install.sh と test.sh が読む。ホームにリンクするファイル（ここに書いたものだけをリンクする）
# shellcheck disable=SC2034  # 読む側のスクリプトで使う
LINK_FILES=(.zshrc .zprofile .gitconfig .config/starship.toml .config/ghostty/config .config/git/ignore .config/mise/config.toml .config/cmux/cmux.json)
