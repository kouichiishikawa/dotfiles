# ログインシェル（ターミナル・zsh -lc）で 1 回だけ読む。対話用の設定は .zshrc に置く

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Global environment variables
export EDITOR='code'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Development paths
# ~/.local/bin: claude・uv の python3（uv python install --default）・uv tool
# mise の shims: zsh -lc で動くジョブ（launchd など）でも node が見つかるようにする。対話シェルでは .zshrc の mise activate が先に来る
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# Docker Desktop
export PATH="$PATH:$HOME/.docker/bin"
