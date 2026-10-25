# ╭──────────────────────────────────────────────────────────╮
# │  Zsh — Starship prompt, autosuggestions, syntax highlight │
# │  Colors follow the terminal palette (= the wallpaper)     │
# ╰──────────────────────────────────────────────────────────╯

export EDITOR=nvim VISUAL=nvim PAGER=less MANPAGER="nvim +Man!"
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/gcr/ssh}"   # gnome-keyring SSH agent (also on the TTY)
typeset -U path PATH
path=(~/.local/bin $path)

# ── History ────────────────────────────────────────────────
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history
mkdir -p ${HISTFILE:h}
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks extended_history

# ── General options ────────────────────────────────────────────
setopt autocd interactive_comments no_beep extended_glob glob_dots

# ── Completion (navigable menu, case-insensitive) ──
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

# ── Keys ───────────────────────────────────────────────────
bindkey -e
bindkey '^[[1;5C' forward-word        # Ctrl+→
bindkey '^[[1;5D' backward-word       # Ctrl+←
bindkey '^[[H'    beginning-of-line   # Home
bindkey '^[[F'    end-of-line         # End
bindkey '^[[3~'   delete-char         # Delete
bindkey '^H'      backward-kill-word  # Ctrl+Backspace
bindkey -M menuselect '^[[Z' reverse-menu-complete  # Shift+Tab no menu

# ── Plugins (Arch packages) ────────────────────────────────
plugins=/usr/share/zsh/plugins
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
[[ -r $plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source $plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source $plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# must come after syntax-highlighting
if [[ -r $plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    source $plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey '^[[A' history-substring-search-up     # ↑ searches history for what has been typed so far
    bindkey '^[[B' history-substring-search-down   # ↓
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=magenta,bold'
fi
unset plugins

# ── fzf: Ctrl+R history · Ctrl+T files · Alt+C folders ───
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

# ── Tools ──────────────────────────────────────────────
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"   # z <part of name> jumps to frequently used folders
export BAT_THEME=ansi                                     # bat uses the terminal colors
# atuin: Ctrl+R = searchable history (folder, session, exit code); ↑ stays the same
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
# direnv: loads/unloads .envrc variables when entering/leaving the folder (direnv allow the first time)
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
# mise: node/python/go/... versions per project (mise.toml or .tool-versions)
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# ── Aliases ──────────────────────────────────────────────────
# lsd: grid with variable-width columns (fills the whole width before wrapping)
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
alias ccu='pnpm dlx ccusage@latest'   # Claude Code token usage (daily, blocks, session)
alias lg='lazygit'
alias help='tldr'                                       # short examples for a command: help tar
alias ..='cd ..' ...='cd ../..'
# System: safe update (Arch news + packages + .pacnew + firmware) and backup
alias update='~/.config/hypr/scripts/update.sh'
alias backup='~/.config/hypr/scripts/backup.sh'
alias py='python'
alias ipy='ipython'

# ── Python: activates .venv automatically when entering the folder ──
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

# Creates a data project with uv: mkds name
mkds() {
    [[ -z $1 ]] && { echo "usage: mkds <project-name>"; return 1; }
    uv init "$1" && cd "$1" &&
    uv add pandas numpy scikit-learn matplotlib seaborn polars pyarrow ipykernel &&
    uv add --dev ipython ruff pytest &&
    _auto_venv && echo "\n✔ Project $1 ready (.venv active)"
}

# ── Yazi: "y" opens the file manager; on quit (q), the shell cd's to its current folder ──
y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX)
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n $cwd && $cwd != $PWD ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# Ctrl+Y toggles the prompt <-> yazi (Ctrl+Y inside yazi quits it, see ~/.config/yazi/keymap.toml)
_yazi_toggle() { zle -I; y; zle reset-prompt }
zle -N _yazi_toggle
bindkey '^Y' _yazi_toggle

# ── fastfetch on terminal open (FASTFETCH_ON_START=0 disables it) ──
# Only in the first shell of a kitty window, outside nvim/yazi/ssh and with room in the window
if [[ ${FASTFETCH_ON_START:-1} == 1 && $TERM == xterm-kitty && $SHLVL -le 1 && -z $NVIM$YAZI_LEVEL$SSH_CONNECTION ]] \
   && (( LINES >= 20 && COLUMNS >= 70 )) && (( $+commands[fastfetch] )); then
    fastfetch
fi

# ── Prompt ───────────────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"
