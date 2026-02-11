# Dotfiles

My personal terminal configuration for macOS, featuring iTerm2, oh-my-zsh, and curated plugins.

## Features

- **oh-my-zsh** with custom plugins:
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions
  - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting
  - [fzf-tab](https://github.com/Aloxaf/fzf-tab) - Replace zsh's default completion with fzf
- **Dracula theme** for zsh
- **Custom aliases and functions**
- **Conda integration**
- **fzf** and **zoxide** for better navigation
- **tmux configuration**
- **Pandoc templates** for PDF generation
- **iTerm2 profile** (Dracula theme + custom settings)

## Prerequisites

- macOS
- Git
- Homebrew (recommended for installing dependencies)

## Quick Setup

Clone this repository and run the install script:

```bash
git clone --recursive https://github.com/kinelhu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The install script will:
- Install oh-my-zsh if not present
- Initialize git submodules for plugins
- Create symlinks for all config files
- Check for optional dependencies

## Manual Installation

If you prefer manual setup:

1. **Clone the repository with submodules:**
   ```bash
   git clone --recursive https://github.com/kinelhu/dotfiles.git ~/.dotfiles
   ```

2. **Initialize submodules (if not cloned with --recursive):**
   ```bash
   cd ~/.dotfiles
   git submodule update --init --recursive
   ```

3. **Create symlinks:**
   ```bash
   ln -sf ~/.dotfiles/.zshrc ~/.zshrc
   ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
   ln -sf ~/.dotfiles/pandoc/header.tex ~/.local/share/pandoc/templates/header.tex

   # oh-my-zsh custom plugins/themes
   ln -sf ~/.dotfiles/oh-my-zsh-custom/plugins/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   ln -sf ~/.dotfiles/oh-my-zsh-custom/plugins/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
   ln -sf ~/.dotfiles/oh-my-zsh-custom/plugins/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
   ln -sf ~/.dotfiles/oh-my-zsh-custom/themes/dracula ~/.oh-my-zsh/custom/themes/dracula
   ```

4. **Install dependencies:**
   ```bash
   brew install fzf zoxide tmux
   ```

5. **Reload shell:**
   ```bash
   source ~/.zshrc
   ```

## iTerm2 Setup

### Option 1: Import Profile (Recommended)
1. Open iTerm2 preferences (`Cmd+,`)
2. Go to **Profiles** → **Other Actions** → **Import JSON Profiles**
3. Select `~/.dotfiles/iterm2/profile.plist`

### Option 2: Copy Preferences File
```bash
cp ~/.dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
```
Then restart iTerm2.

## Updating

### Syncing Configuration Changes

After editing any config files (`.zshrc`, `.tmux.conf`, etc.), use the sync script:

```bash
cd ~/.dotfiles
./sync.sh
```

Or manually:
```bash
cd ~/.dotfiles
git add .
git commit -m "Update configuration"
git push
```

On other machines, pull the changes:
```bash
cd ~/.dotfiles
git pull
source ~/.zshrc  # Reload shell if .zshrc changed
```

### Update Plugins to Latest Versions
```bash
cd ~/.dotfiles
git submodule update --remote --merge
git add .
git commit -m "Update plugins"
git push
```

### Pull Latest Changes from Remote
```bash
cd ~/.dotfiles
git pull
git submodule update --init --recursive
```

## Dependencies

### Required
- **oh-my-zsh** - Installed automatically by install.sh

### Optional but Recommended
- **fzf** - Fuzzy finder (`brew install fzf`)
- **zoxide** - Smart directory jumper (`brew install zoxide`)
- **tmux** - Terminal multiplexer (`brew install tmux`)
- **conda/miniconda** - Python environment management

## Structure

```
~/.dotfiles/
├── README.md                    # This file
├── CLAUDE.md                    # Development guide (for Claude or contributors)
├── install.sh                   # Bootstrap script for new machines
├── sync.sh                      # Helper script to commit and push changes
├── .zshrc                       # Main zsh configuration
├── .tmux.conf                   # tmux configuration
├── iterm2/
│   ├── profile.plist           # iTerm2 preferences (readable format)
│   └── com.googlecode.iterm2.plist  # iTerm2 binary plist
├── pandoc/
│   └── header.tex              # Pandoc PDF header template
└── oh-my-zsh-custom/
    ├── plugins/
    │   ├── zsh-autosuggestions/    (submodule)
    │   ├── zsh-syntax-highlighting/ (submodule)
    │   └── fzf-tab/                (submodule)
    └── themes/
        └── dracula/                (submodule)
```

## Customization

### How Symlinks Work

The install script creates **symlinks**, meaning:
- `~/.zshrc` → `~/.dotfiles/.zshrc`
- When you edit `~/.zshrc`, you're editing the file in the git repo
- No need to copy files back - they're the same file!

### Making Changes

1. Edit config files normally (e.g., `vim ~/.zshrc`)
2. Sync to git:
   ```bash
   cd ~/.dotfiles
   ./sync.sh  # Interactive helper
   ```

### Adding New Config Files

See `CLAUDE.md` for detailed instructions on:
- Adding new configuration files
- Adding new zsh plugins
- Updating iTerm2 preferences
- And more development workflows

## Troubleshooting

### Plugins not loading
Make sure submodules are initialized:
```bash
cd ~/.dotfiles
git submodule update --init --recursive
```

### Symlinks not working
Check if symlinks are created correctly:
```bash
ls -la ~ | grep "\->"
ls -la ~/.oh-my-zsh/custom/plugins/
```

### iTerm2 profile not importing
Try copying the plist file directly instead of importing:
```bash
cp ~/.dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
```

## License

MIT License - Feel free to use and modify as needed.
