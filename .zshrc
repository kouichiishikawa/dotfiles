# 対話シェルの設定。環境変数と PATH の土台は .zprofile

# 履歴
# ====
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history share_history extended_history
setopt hist_ignore_all_dups hist_save_no_dups hist_ignore_space hist_reduce_blanks

# パス設定
# ==========
typeset -U path
path=(
    $HOME/.pixi/bin
    $HOME/.config/yarn/global/node_modules/.bin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    $path
)

# Node などのバージョン管理（mise）。Python は uv（~/.local/bin の python3）
eval "$(mise activate zsh)"

# Python
export PIP_REQUIRE_VIRTUALENV=true

# 補完（compinit は 1 回だけ。ダンプが 1 日以内なら検査を省く）
# ====
fpath=($HOME/.docker/completions /opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
() { if (( $# )); then compinit -C; else compinit; fi } ${ZDOTDIR:-$HOME}/.zcompdump(N.mh-24)

# Carapace補完（pixi等）
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# ツール
# ======
# Ctrl+T・Alt+C（Ctrl+R は下の atuin が持つ）。端末の無い zsh -i -c では zle が使えず警告が出るので読まない
[[ -t 0 ]] && source <(fzf --zsh)
eval "$(zoxide init zsh)"                 # z <dir>
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(starship init zsh)"

# エイリアス
# ==========
alias ls='eza --group-directories-first'
alias ll='eza -la --git --group-directories-first'
alias tree='eza --tree'
alias cat='bat --paging=never --style=plain'
alias g='git'
alias dc='docker-compose'
alias py='python3'

# 開発ファイルをVS Codeで開く
alias edit='code'

# 開発用ファイルの関数定義
open_with_code() {
    local file="$1"
    if [[ -f "$file" ]]; then
        case "$file" in
            *.py|*.js|*.ts|*.jsx|*.tsx|*.vue|*.php|*.rb|*.go|*.rs|*.java|*.cpp|*.c|*.h|*.hpp|*.css|*.scss|*.sass|*.less|*.html|*.xml|*.json|*.yaml|*.yml|*.toml|*.ini|*.cfg|*.conf|*.sh|*.bash|*.zsh|*.fish|*.sql|*.md|*.txt|*.csv|*.log|*.env|*.gitignore|*.dockerignore|Dockerfile|Makefile|*.mk|*.cmake|CMakeLists.txt|*.lock|*.sum|*.mod|requirements.txt|package.json|composer.json|Gemfile|Cargo.toml|pyproject.toml|setup.py|setup.cfg|tox.ini|.flake8|.pylintrc|.mypy.ini|.pre-commit-config.yaml|.github/workflows/*|.gitlab-ci.yml|.travis.yml|.circleci/config.yml)
                code "$file"
                ;;
            *)
                open "$file"
                ;;
        esac
    else
        echo "File not found: $file"
    fi
}

# 'o' コマンドを開発ファイル用に設定
alias o='open_with_code'

# MCP 用のトークンは 1Password Environments の Local .env file（名前付きパイプ）から、claude の起動時だけ読む。
# シェルを開いただけでは読まない。承認は 1Password がロックされるまで 1 回。値はこのシェルには残さない（サブシェルで渡す）
CLAUDE_ENV_FILE=~/.config/op-env/claude.env
claude() {
  if [[ ! -p $CLAUDE_ENV_FILE ]]; then
    print -u2 "claude: $CLAUDE_ENV_FILE が 1Password からマウントされていません。MCP のトークンなしで起動します"
    command claude "$@"; return
  fi
  (
    local line
    while IFS= read -r line || [[ -n $line ]]; do
      [[ $line =~ '^[A-Za-z_][A-Za-z0-9_]*=' ]] || continue
      line=${line%$'\r'}
      local k=${line%%=*} v=${line#*=}
      [[ $v == \"*\" || $v == \'*\' ]] && v=${v:1:-1}
      export "$k=$v"
    done < $CLAUDE_ENV_FILE
    exec command claude "$@"
  )
}

# zsh のプラグイン（brew）。syntax-highlighting は最後に読む
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
