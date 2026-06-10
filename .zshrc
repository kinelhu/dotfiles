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
plugins=(git
	zsh-syntax-highlighting
	zsh-autosuggestions
	fzf
	zoxide)

source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)

# Setup Oh My Posh
# eval "$(oh-my-posh init zsh)"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

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
export PATH="/opt/homebrew/opt/binutils/bin:$PATH"

eval "$(zoxide init zsh)"

alias sync-metro='rsync -avz --exclude="venv" --exclude="__pycache__" --exclude="*.pyc" ~/Projects/metro-display/ kinelhu@metro-display.home:~/metro-display/'

alias gitlg='git log --pretty=oneline'

# Pandoc wrappers — options centralisées dans ~/.local/share/pandoc/defaults/
mdpdf() {
  local input="$1" dir
  dir="$(cd "$(dirname "$input")" && pwd)"
  pandoc "$input" -o "${input%.md}.pdf" \
    --defaults ~/.local/share/pandoc/defaults/article-kinan.yaml \
    --resource-path "$dir" \
    "${@:2}"
}

mddocx() {
  local input="$1" dir out
  dir="$(cd "$(dirname "$input")" && pwd)"
  out="${input%.md}.docx"
  # Write to a tmp file then mv so Word reloads even if it had the file open
  local tmp; tmp="$(mktemp /tmp/mddocx-XXXXXX.docx)"
  pandoc "$input" -o "$tmp" \
    --defaults ~/.local/share/pandoc/defaults/docx-kinan.yaml \
    --resource-path "$dir" \
    "${@:2}" && mv "$tmp" "$out" && echo "→ $out"
}

mdslides() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    cat <<'EOF'
Usage: mdslides <file.md> [--handout] [pandoc options...]

Compile a Markdown file to a Beamer PDF using the slides-kinan defaults.

Flags
  --handout         Also produce <file>-handout.pdf (\pause overlays collapsed)
  --draft           Fast draft PDF (images replaced by boxes) — layout check only

YAML front matter fields
  notes: show       Notes printed below each slide
  notes: only       Notes-only PDF (use as speaker script)
  notes: right      Dual-screen PDF — slides left, notes right
                    (open with pympress or pdfpc)
  (absent)          Notes hidden; normal slide PDF

Examples
  mdslides talk.md
  mdslides talk.md --handout
  mdslides talk.md --metadata notes=right   # override without editing the file
EOF
    return 0
  fi

  local input="$1" dir tmp notes_opt
  dir="$(cd "$(dirname "$input")" && pwd)"

  # Sépare les flags custom des args pandoc
  local do_handout=false
  local do_draft=false
  local extra_args=()
  for arg in "${@:2}"; do
    case "$arg" in
      --handout) do_handout=true ;;
      --draft)   do_draft=true ;;
      *)         extra_args+=("$arg") ;;
    esac
  done

  # Lit le champ notes: dans le front matter YAML
  notes_opt=$(python3 -c "
import re, sys
c = open(sys.argv[1]).read()
m = re.search(r'^---\n(.*?)\n---', c, re.DOTALL)
if m:
    n = re.search(r'^notes:\s*(.+)$', m.group(1), re.M)
    if n: print(n.group(1).strip().strip('\"\''))
" "$input" 2>/dev/null)

  # Les args CLI --metadata notes=VALUE / -M notes=VALUE prennent la priorité
  local prev=""
  for arg in "${extra_args[@]}"; do
    if [[ "$prev" == "--metadata" || "$prev" == "-M" ]] && [[ "$arg" == notes=* ]]; then
      notes_opt="${arg#notes=}"
    elif [[ "$arg" == --metadata=notes=* ]]; then
      notes_opt="${arg#--metadata=notes=}"
    elif [[ "$arg" == -Mnotes=* ]]; then
      notes_opt="${arg#-Mnotes=}"
    fi
    prev="$arg"
  done

  # Écrit le header LaTeX dans un fichier temporaire
  tmp=$(mktemp /tmp/mdslides-XXXXXX.tex)
  printf '\\graphicspath{{%s/}}\n' "$dir" > "$tmp"
  case "$notes_opt" in
    show)  printf '\\setbeameroption{show notes}\n'                        >> "$tmp" ;;
    only)  printf '\\setbeameroption{show only notes}\n'                   >> "$tmp" ;;
    right) printf '\\setbeameroption{show notes on second screen=right}\n' >> "$tmp" ;;
  esac

  if [[ "$do_draft" == true ]]; then
    pandoc "$input" -o "${input%.md}-draft.pdf" \
      --defaults ~/.local/share/pandoc/defaults/slides-kinan.yaml \
      --resource-path "$dir" \
      -H "$tmp" \
      -V classoption=draft \
      -V classoption=aspectratio=169 \
      "${extra_args[@]}"
  else
    pandoc "$input" -o "${input%.md}-slides.tex" \
      --defaults ~/.local/share/pandoc/defaults/slides-kinan.yaml \
      --resource-path "$dir" \
      -H "$tmp" \
      "${extra_args[@]}"

    pandoc "$input" -o "${input%.md}-slides.pdf" \
      --defaults ~/.local/share/pandoc/defaults/slides-kinan.yaml \
      --resource-path "$dir" \
      -H "$tmp" \
      "${extra_args[@]}"

    if [[ "$do_handout" == true ]]; then
      pandoc "$input" -o "${input%.md}-handout.pdf" \
        --defaults ~/.local/share/pandoc/defaults/slides-kinan.yaml \
        --resource-path "$dir" \
        -H "$tmp" \
        -V classoption=handout \
        -V classoption=aspectratio=169 \
        "${extra_args[@]}"
    fi
  fi

  rm -f "$tmp"
}

mdhtml() {
  pandoc "$1" -o "${1%.md}.html" --standalone --embed-resources --css ~/.local/share/pandoc/css/clean.css "${@:2}"
}

fpath+=("$(brew --prefix)/share/zsh/site-functions")

ZSH_THEME="dracula"

# Two conda installs
# Quick switch for ARM64 Miniforge
alias load_native='export PATH="/Users/kinelhu/miniforge_native/bin:$PATH"; conda init zsh; source ~/.zshrc'

# Quick switch for Intel Miniforge (replace with your actual path)
alias load_intel='export PATH="/opt/miniconda3/bin:$PATH"; conda init zsh; source ~/.zshrc'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Remove certain autosuggestion patterns (plugin zah-autosuggestions)
ZSH_AUTOSUGGEST_HISTORY_IGNORE="export *"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kinelhu/.lmstudio/bin"
# End of LM Studio CLI section


# bun completions
[ -s "/Users/kinelhu/.bun/_bun" ] && source "/Users/kinelhu/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

mdtoc() {
  if [[ -z "$1" ]]; then
    echo "Usage: mdtoc <file.md> [max_depth]"
    return 1
  fi

  local input="$1"
  local maxdepth="${2:-6}"
  local dir="$(dirname "$input")"
  local base="$(basename "$input" .md)"
  local output="${dir}/${base}_toc.md"

  echo "# Table of Contents" > "$output"
  echo "" >> "$output"

  awk -v maxdepth="$maxdepth" '
    /^```/ { in_code = !in_code; next }
    in_code { next }
    /^#/ {
      hashes = $1
      n = length(hashes)
      if (n <= maxdepth) {
        sub(/^#+[[:space:]]/, "")
        indent = sprintf("%*s", (n-1)*2, "")
        print indent "- " $0
      }
    }
  ' "$input" >> "$output"

  echo "TOC written to: $output"
}

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
