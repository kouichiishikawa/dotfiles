# 基本設定
# ==========
setopt append_history
setopt share_history

# パス設定
# ==========
typeset -U path
path=(
    /opt/homebrew/bin
    /opt/homebrew/sbin
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)

# ツール設定関数
# ==============
setup_php() {
    path=(
        /opt/homebrew/opt/php@8.1/bin
        /opt/homebrew/opt/php@8.1/sbin
        $path
    )
}

setup_yarn() {
    path=(
        $HOME/.config/yarn/global/node_modules/.bin
        $(yarn global bin 2>/dev/null)
        $path
    )
}

setup_node() {
    # nvmのセットアップ
    export NVM_DIR="$HOME/.nvm"
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh" --no-use  # --no-useフラグを追加
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

    # デフォルトのNode.jsバージョンを使用
    nvm use default >/dev/null 2>&1

    # yarnのセットアップ
    setup_yarn
}

# Python (pyenv)
setup_python() {
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && path=($PYENV_ROOT/bin $path)
    eval "$(pyenv init -)"
}

# Ruby (rbenv)
setup_ruby() {
    # rbenvが存在する場合のみ初期化を実行
    if command -v rbenv >/dev/null 2>&1; then
        eval "$(rbenv init - --no-rehash)"
    fi
}

# 各ツールのセットアップを実行
# ==========================
setup_php
setup_python
setup_node
setup_ruby

# エイリアス
# ==========
alias ll='ls -la'
alias g='git'
alias dc='docker-compose'

# Git補完
# =======
autoload -Uz compinit && compinit

# プロンプト設定
# ============
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f ${vcs_info_msg_0_}
$ '

# 履歴設定
# =======
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000