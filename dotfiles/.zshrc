# ╭──────────────────────────────────────────────────────────╮
# │  Zsh — prompt Starship, autosugestões, syntax highlight   │
# │  As cores seguem a paleta do terminal (= do wallpaper)    │
# ╰──────────────────────────────────────────────────────────╯

export EDITOR=nvim VISUAL=nvim PAGER=less MANPAGER="nvim +Man!"
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/gcr/ssh}"   # agente SSH do gnome-keyring (também no TTY)
typeset -U path PATH
path=(~/.local/bin $path)

# ── Histórico ────────────────────────────────────────────────
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history
mkdir -p ${HISTFILE:h}
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks extended_history

# ── Opções gerais ────────────────────────────────────────────
setopt autocd interactive_comments no_beep extended_glob glob_dots

# ── Completion (menu navegável, sem diferenciar maiúsculas) ──
autoload -Uz compinit
mkdir -p ~/.cache/zsh
compinit -d ~/.cache/zsh/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{magenta}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/compcache
zmodload zsh/complist

# ── Teclas ───────────────────────────────────────────────────
bindkey -e
bindkey '^[[1;5C' forward-word        # Ctrl+→
bindkey '^[[1;5D' backward-word       # Ctrl+←
bindkey '^[[H'    beginning-of-line   # Home
bindkey '^[[F'    end-of-line         # End
bindkey '^[[3~'   delete-char         # Delete
bindkey '^H'      backward-kill-word  # Ctrl+Backspace
bindkey -M menuselect '^[[Z' reverse-menu-complete  # Shift+Tab no menu

# ── Plugins (pacotes do Arch) ────────────────────────────────
plugins=/usr/share/zsh/plugins
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
[[ -r $plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source $plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source $plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# precisa vir depois do syntax-highlighting
if [[ -r $plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    source $plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey '^[[A' history-substring-search-up     # ↑ busca no histórico pelo que já foi digitado
    bindkey '^[[B' history-substring-search-down   # ↓
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=magenta,bold'
fi
unset plugins

# ── fzf: Ctrl+R histórico · Ctrl+T arquivos · Alt+C pastas ───
if (( $+commands[fzf] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
    export FZF_DEFAULT_OPTS="--height 45% --layout reverse --border rounded --info inline-right \
        --prompt '❯ ' --pointer '▌' --marker '│' \
        --color=fg:-1,bg:-1,hl:5,fg+:-1,bg+:0,hl+:5,info:4,prompt:5,pointer:5,marker:2,spinner:5,header:4,border:8,gutter:-1"
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :200 {}'"
    export FZF_ALT_C_OPTS="--preview 'lsd --tree --depth 2 --color always --icon always {} 2>/dev/null || eza --tree --level 2 --icons --color=always {}'"
    source <(fzf --zsh)
fi

# ── Ferramentas ──────────────────────────────────────────────
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"   # z <parte do nome> pula para pastas usadas
export BAT_THEME=ansi                                     # bat usa as cores do terminal
# atuin: Ctrl+R = histórico pesquisável (pasta, sessão, código de saída); ↑ continua igual
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
# direnv: carrega/descarrega variáveis do .envrc ao entrar/sair da pasta (direnv allow na 1ª vez)
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
# mise: versões de node/python/go/... por projeto (mise.toml ou .tool-versions)
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# ── Aliases ──────────────────────────────────────────────────
# lsd: grade com colunas de largura variável (ocupa toda a largura antes de quebrar linha)
if (( $+commands[lsd] )); then
    alias ls='lsd'
    alias ll='lsd -l --git'
    alias la='lsd -lA --git'
    alias lt='lsd --tree --depth 2'
elif (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first --time-style=relative'
    alias la='eza -la --icons --git --group-directories-first --time-style=relative'
    alias lt='eza --tree --level 2 --icons'
fi
(( $+commands[bat] )) && alias cat='bat --style=plain --paging=never'
alias grep='grep --color=auto'
alias v='nvim' vim='nvim'
alias lg='lazygit'
alias help='tldr'                                       # exemplos curtos de um comando: help tar
alias ..='cd ..' ...='cd ../..'
# Sistema: atualização segura (notícias do Arch + pacotes + .pacnew + firmware) e backup
alias update='~/.config/hypr/scripts/update.sh'
alias backup='~/.config/hypr/scripts/backup.sh'
alias py='python'
alias ipy='ipython'

# ── Python: ativa a .venv automaticamente ao entrar na pasta ──
autoload -Uz add-zsh-hook
_auto_venv() {
    local dir=$PWD
    while [[ $dir != / ]]; do
        if [[ -f $dir/.venv/bin/activate ]]; then
            [[ $VIRTUAL_ENV == $dir/.venv ]] || source $dir/.venv/bin/activate
            return
        fi
        dir=${dir:h}
    done
    [[ -n $VIRTUAL_ENV ]] && (( $+functions[deactivate] )) && deactivate
}
add-zsh-hook chpwd _auto_venv
_auto_venv

# Cria um projeto de dados com uv: mkds nome
mkds() {
    [[ -z $1 ]] && { echo "uso: mkds <nome-do-projeto>"; return 1; }
    uv init "$1" && cd "$1" &&
    uv add pandas numpy scikit-learn matplotlib seaborn polars pyarrow ipykernel &&
    uv add --dev ipython ruff pytest &&
    _auto_venv && echo "\n✔ Projeto $1 pronto (.venv ativa)"
}

# ── Yazi: "y" abre o gerenciador de arquivos; ao sair (q), o shell vai para a pasta atual dele ──
y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX)
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# ── Prompt ───────────────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"
