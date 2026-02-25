# CLAUDE.md - Dotfiles Project Guide

## Project Overview

This is a dotfiles repository for managing terminal configuration across multiple machines. It uses **symlinks** for config files, meaning edits to files like `~/.zshrc` automatically update the git repository (since they point to `~/.dotfiles/.zshrc`).

**Repository**: https://github.com/kinelhu/dotfiles

## File Structure

```
~/.dotfiles/
├── .zshrc                  # Main zsh config (symlinked to ~/.zshrc)
├── .tmux.conf             # tmux config (symlinked to ~/.tmux.conf)
├── .gitconfig             # Git config (symlinked to ~/.gitconfig)
├── install.sh             # Bootstrap script for new machines
├── sync.sh                # Helper to commit/push changes
├── README.md              # User-facing documentation
├── CLAUDE.md              # This file - development guide
├── Brewfile                # Homebrew packages (brew bundle install)
├── alfred/
│   └── Alfred.alfredpreferences/  # Alfred settings (symlinked to ~/Library/Application Support/Alfred/Alfred.alfredpreferences)
│       ├── preferences/           # General Alfred settings
│       ├── workflows/             # Alfred workflows
│       ├── remote/                # Alfred Remote settings
│       └── resources/             # Resources (icons, etc.)
├── vscode/
│   ├── settings.json      # VS Code settings (symlinked to ~/Library/Application Support/Code/User/settings.json)
│   ├── keybindings.json   # VS Code keybindings (symlinked)
│   └── extensions.txt     # Extension list (install with: cat extensions.txt | xargs -L1 code --install-extension)
├── positron/
│   └── settings.json      # Positron settings (symlinked to ~/Library/Application Support/Positron/User/settings.json)
├── iterm2/
│   ├── com.googlecode.iterm2.plist  # Binary plist backup
│   └── profile.plist                 # Readable plist export
├── pandoc/
│   └── header.tex         # Pandoc PDF header template
└── oh-my-zsh-custom/
    ├── plugins/           # zsh plugins (git submodules)
    │   ├── zsh-autosuggestions/
    │   ├── zsh-syntax-highlighting/
    │   └── fzf-tab/
    └── themes/            # zsh themes (git submodules)
        └── dracula/
```

## Key Concepts

### Symlinks
The install script creates symlinks, so:
- Editing `~/.zshrc` edits `~/.dotfiles/.zshrc` (already in git)
- No need to copy files back - they're the same file
- Changes are immediately tracked by git

### Git Submodules
Plugins and themes are tracked as submodules:
- Keeps plugin code separate from our dotfiles
- Easy to update to latest plugin versions
- Each submodule has its own git history

## Common Workflows

### 1. Updating Configuration on Primary Machine

After editing any config file (`.zshrc`, `.tmux.conf`, etc.):

```bash
cd ~/.dotfiles
./sync.sh  # Interactive commit + push
```

Or manually:
```bash
cd ~/.dotfiles
git status              # See what changed
git diff                # Review changes
git add .
git commit -m "Description of changes"
git push
```

### 2. Syncing Changes to Other Machines

On secondary machines:
```bash
cd ~/.dotfiles
git pull
source ~/.zshrc  # Reload shell config if .zshrc changed
```

### 3. Updating Plugins to Latest Versions

```bash
cd ~/.dotfiles
git submodule update --remote --merge
git add .
git commit -m "Update zsh plugins to latest versions"
git push
```

Then on other machines: `cd ~/.dotfiles && git pull && git submodule update --init --recursive`

### 4. Adding a New Config File

Example: Adding `.gitconfig`

```bash
cd ~/.dotfiles
cp ~/.gitconfig .gitconfig    # Copy the file
git add .gitconfig
git commit -m "Add .gitconfig"
git push
```

Then update `install.sh` to create the symlink:
```bash
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
```

### 5. Adding a New zsh Plugin

Example: Adding `zsh-history-substring-search`

```bash
cd ~/.dotfiles
git submodule add https://github.com/zsh-users/zsh-history-substring-search oh-my-zsh-custom/plugins/zsh-history-substring-search
git add .
git commit -m "Add zsh-history-substring-search plugin"
git push
```

Then update `.zshrc` to include it in the `plugins=()` array and update `install.sh` to symlink it.

### 6. Removing a Plugin

```bash
cd ~/.dotfiles
git submodule deinit oh-my-zsh-custom/plugins/PLUGIN_NAME
git rm oh-my-zsh-custom/plugins/PLUGIN_NAME
rm -rf .git/modules/oh-my-zsh-custom/plugins/PLUGIN_NAME
git commit -m "Remove PLUGIN_NAME"
git push
```

Also remove from `plugins=()` in `.zshrc`.

### 7. Updating Homebrew Packages

After installing/removing packages:

```bash
brew bundle dump --file=~/.dotfiles/Brewfile --force
cd ~/.dotfiles
git add Brewfile
git commit -m "Update Brewfile"
git push
```

On a new machine, `install.sh` runs `brew bundle install` automatically.

### 8. Updating VS Code / Positron Settings

Settings are symlinked, so edits in the editors are tracked automatically. To also capture any new extensions:

```bash
code --list-extensions > ~/.dotfiles/vscode/extensions.txt
cd ~/.dotfiles
git add vscode/ positron/
git commit -m "Update editor settings"
git push
```

### 9. Updating Alfred Preferences

Alfred is symlinked, so any changes you make in Alfred are automatically tracked in git. Just sync when you want to commit them:

```bash
cd ~/.dotfiles
git add alfred/
git commit -m "Update Alfred preferences"
git push
```

On a new machine, `install.sh` will link `~/.dotfiles/alfred/Alfred.alfredpreferences` to `~/Library/Application Support/Alfred/Alfred.alfredpreferences` automatically.

### 8. Updating iTerm2 Preferences

After changing iTerm2 settings:

```bash
# Export updated preferences
defaults read com.googlecode.iterm2 > ~/.dotfiles/iterm2/profile.plist
cp ~/Library/Preferences/com.googlecode.iterm2.plist ~/.dotfiles/iterm2/com.googlecode.iterm2.plist

cd ~/.dotfiles
git add iterm2/
git commit -m "Update iTerm2 preferences"
git push
```

### 8. Fresh Install on New Machine

```bash
git clone --recursive https://github.com/kinelhu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
source ~/.zshrc
```

## Important Notes

### Symlink Awareness
- Because files are symlinked, editing `~/.zshrc` directly updates the repo
- Always work in `~/.dotfiles` for git operations
- The actual files live in `~/.dotfiles/`, not `~/`

### Backup Safety
- `install.sh` backs up existing files with timestamp: `.backup.YYYYMMDD_HHMMSS`
- Safe to run multiple times (idempotent)

### Dependencies
The setup requires:
- oh-my-zsh (installed by script)
- git
- Optional: fzf, zoxide, tmux (warned about by script)

### Conda Integration
The `.zshrc` includes conda initialization. The conda paths are:
- `/opt/anaconda3` (primary)
- `/Users/kinelhu/miniconda3` (fallback)

If conda is installed elsewhere on a new machine, update the paths in `.zshrc`.

## Troubleshooting

### "Changes not showing up in git"
- Remember: files are symlinked! Your edits ARE in the repo
- Run `cd ~/.dotfiles && git status` to see changes

### "Plugins not loading after update"
```bash
cd ~/.dotfiles
git submodule update --init --recursive
source ~/.zshrc
```

### "iTerm2 import not working"
Try direct copy instead:
```bash
cp ~/.dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
```
Then restart iTerm2.

### "Merge conflicts after pull"
Usually happens with `.zshrc` if both machines had different local changes:
```bash
cd ~/.dotfiles
git status  # See which files conflict
# Edit files to resolve conflicts (remove <<<< ==== >>>> markers)
git add .
git commit -m "Resolve merge conflicts"
git push
```

## Expansion Ideas

As you customize more, consider adding:
- `.vimrc` / `.config/nvim/` (if using vim/neovim)
- `.gitconfig` and `.gitignore_global`
- VS Code settings (`~/Library/Application Support/Code/User/settings.json`)
- SSH config (`~/.ssh/config` - **careful with private keys!**)
- `.config/` directory for other tools
- Brewfile for package management
- Scripts folder for custom utilities

## Security Warnings

**Never commit:**
- Private SSH/GPG keys
- API tokens or credentials
- `.env` files with secrets
- Password files

Use `.gitignore` to exclude sensitive paths.

## Quick Reference Commands

```bash
# Check current status
cd ~/.dotfiles && git status

# Quick sync
cd ~/.dotfiles && ./sync.sh

# Update plugins
cd ~/.dotfiles && git submodule update --remote --merge

# Pull latest
cd ~/.dotfiles && git pull

# Add new file
cp ~/newfile ~/.dotfiles/ && cd ~/.dotfiles && git add newfile

# View submodule status
cd ~/.dotfiles && git submodule status
```

## Development Philosophy

- **Keep it simple**: Don't over-engineer. Only add files you actually customize
- **Document changes**: Good commit messages help future you
- **Test on fresh clone**: Occasionally test the install script in a VM or new machine
- **Modular**: Each config file should work independently where possible
- **Portable**: Avoid hardcoding absolute paths (use `$HOME` variables)

---

**Last Updated**: 2026-02-11
**Maintainer**: Kinan El Husseini
