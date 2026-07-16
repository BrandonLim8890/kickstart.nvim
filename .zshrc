# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  fzf-tab
  git
  npm
  zsh-autosuggestions
  # zsh-autocomplete
  z
)

zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
eval "$(fzf --zsh)"

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source ~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias serve="NODE_ARGS='--max_old_space_size=16384' bend reactor serve --update --ts-watch --enable-tools"
alias sserve="bend reactor serve --update --ts-watch --enable-tools"
alias testserve="NODE_ARGS='--max_old_space_size=16384' bend reactor serve --update --ts-watch --enable-tools --run-tests"
alias gsync="git branch --merged | grep -v "master" >/tmp/merged-branches && nvim /tmp/merged-branches && xargs git branch -d </tmp/merged-branches"
function atest() {
  local at_dir=$(find . -maxdepth 1 -type d -name "*acceptance-tests" | head -1)
  if [ -z "$at_dir" ]; then
    echo "No acceptance test directory found"
    return 1
  fi
  (cd "$at_dir" && bend yarn && bend yarn hs-test --local-app -b chrome)
}
alias gw="git worktree"
# nvim/opencode socket wrapper definitions live at the very bottom of this
# file (after ~/.hubspot/shellrc is sourced) so they win over HubSpot's
# `opencode` alias. See bottom of file.
function log() {
  mkdir -p temp
  "$@" | tee temp/shell_log.txt
}

function bvim() {
  local base="$PWD"

  local selected
  selected=$(find "$base" -mindepth 1 -maxdepth 1 -type d \
    | while read -r dir; do [ -d "$dir/.git" ] && basename "$dir"; done \
    | fzf --multi --prompt="Select projects: " --header="Tab to select multiple")

  [ -z "$selected" ] && return

  local dirs=()
  while IFS= read -r name; do
    dirs+=("$base/$name")
  done <<< "$selected"

  if [ ${#dirs[@]} -eq 1 ]; then
    cd "${dirs[0]}" && BEND_DIRS="${dirs[0]}" vim . </dev/null
  else
    local bend_dirs=$(IFS=:; echo "${dirs[*]}")
    BEND_DIRS="$bend_dirs" vim . </dev/null
  fi
}

function bupdate() {
  local base="$PWD"

  # Find all repos with a static_conf.json, show as "category/repo" relative to base
  local selected
  selected=$(find "$base" -mindepth 2 -maxdepth 2 -name "static_conf.json" \
    | while read -r conf; do
        local repo_dir
        repo_dir=$(dirname "$conf")
        echo "${repo_dir#$base/}"
      done \
    | sort \
    | fzf --multi --prompt="Select repos: " --header="Tab to select multiple, Enter to confirm")

  [ -z "$selected" ] && return

  # Group selected repos by their parent dir, collecting all package names per parent
  declare -A parent_to_packages
  while IFS= read -r rel_path; do
    local abs_path="$base/$rel_path"
    local parent_dir
    parent_dir=$(dirname "$abs_path")
    local conf="$abs_path/static_conf.json"
    local pkgs
    pkgs=$(python3 -c "import json,sys; d=json.load(open('$conf')); print(' '.join(d.get('packages',[])))" 2>/dev/null)
    if [[ -n "$pkgs" ]]; then
      if [[ -n "${parent_to_packages[$parent_dir]}" ]]; then
        parent_to_packages[$parent_dir]="${parent_to_packages[$parent_dir]} $pkgs"
      else
        parent_to_packages[$parent_dir]="$pkgs"
      fi
    fi
  done <<< "$selected"

  # Run bend install --update then bend generate-code per parent dir
  for parent_dir in "${(@k)parent_to_packages}"; do
    local pkgs="${parent_to_packages[$parent_dir]}"
    echo "==> cd $parent_dir"
    echo "==> bend install --update $pkgs"
    (cd "$parent_dir" && bend install --update $pkgs) || { echo "bend install failed in $parent_dir"; return 1; }
    echo "==> bend generate-code $pkgs"
    (cd "$parent_dir" && bend generate-code $pkgs) || { echo "bend generate-code failed in $parent_dir"; return 1; }
  done
}

function cleanup() {
  echo "Running cleanup tasks concurrently..."
  bend gc &
  bpm gc &
  bend yarn cache clean &
  brew cleanup --prune=all &
  wait
  if [ $? -eq 0 ]; then
    echo "✓ All cleanup tasks completed successfully"
  else
    echo "✗ Some cleanup tasks failed"
    return 1
  fi
}

autoload -Uz compinit && compinit

# Added by nex: https://git.hubteam.com/HubSpot/nex
# [ -f ~/.hubspot/shellrc ] && . ~/.hubspot/shellrc

# Added by nex: https://git.hubteam.com/HubSpot/nex
[ -e ~/.hubspot/shellrc ] && . ~/.hubspot/shellrc

# Raise file descriptor limit for nvim in large monorepos
ulimit -n 65536

# --- nvim <-> opencode MCP socket bridge ---
# Defined AFTER ~/.hubspot/shellrc so these win over HubSpot's `opencode` alias.
unalias vim 2>/dev/null
unalias nvim 2>/dev/null
unalias opencode 2>/dev/null

_nvim_socket() { echo "/tmp/nvim-$(echo "$PWD" | md5 | cut -c1-8)" }

vim() {
  local socket="$(_nvim_socket)"
  if [[ ! -S "$socket" ]]; then
    command nvim --listen "$socket" "$@"
  else
    command nvim "$@"
  fi
}
alias nvim=vim

# Wraps HubSpot's `dvx opencode` launcher so the MCP child process inherits
# NVIM_SOCKET_PATH keyed to the current directory.
opencode() {
  local socket="$(_nvim_socket)"
  NVIM_SOCKET_PATH="$socket" dvx opencode "$@"
}
