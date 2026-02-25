# Dotfiles

My personal configuration for macOS — terminal, editors, apps, and packages.

## What's tracked

| App / Tool | What's stored | How |
|---|---|---|
| **zsh** | `.zshrc` | Symlink |
| **tmux** | `.tmux.conf` | Symlink |
| **git** | `.gitconfig` | Symlink |
| **iTerm2** | Preferences plist + profile | Copied on sync |
| **Alfred** | Full `Alfred.alfredpreferences` | Symlink |
| **VS Code** | `settings.json`, `keybindings.json`, extension list | Symlink + list |
| **Positron** | `settings.json` | Symlink |
| **Zotero** | `user.js` preferences + 4 plugins (`.xpi`) | Copied on sync/install |
| **Pandoc** | All templates in `~/.local/share/pandoc/templates/` | Symlink (whole dir) |
| **Homebrew** | `Brewfile` (formulae + casks) | Generated on sync |
| **oh-my-zsh** | Plugins + Dracula theme | Git submodules |

> **Symlinked** files are live — edits in the app instantly update the git repo with no copying needed.

---

## Quick setup on a new machine

```bash
git clone --recursive https://github.com/kinelhu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

`install.sh` will:
1. Install oh-my-zsh if missing
2. Initialize git submodules (zsh plugins + Dracula theme)
3. Create all symlinks
4. Run `brew bundle install` to restore all Homebrew packages and casks
5. Install VS Code extensions
6. Copy Zotero plugins and `user.js` into the active Zotero profile

> **After install:** open Zotero and download [Better BibTeX](https://github.com/retorquere/zotero-better-bibtex/releases) manually (too large to store in git). Also update the machine-specific paths in `~/.dotfiles/zotero/user.js`.

---

## Syncing changes (day-to-day)

One command captures everything and pushes to GitHub:

```bash
~/.dotfiles/sync.sh
```

This will automatically refresh:
- Brewfile (new/removed packages)
- VS Code extension list
- iTerm2 preferences
- Zotero plugin files

Then shows a diff, asks for a commit message, and pushes.

To pull on another machine:
```bash
cd ~/.dotfiles && git pull
source ~/.zshrc
```

---

## Structure

```
~/.dotfiles/
├── install.sh                   # Bootstrap for new machines
├── sync.sh                      # One-command sync & push
├── Brewfile                     # Homebrew formulae + casks
├── .zshrc                       # zsh config → ~/.zshrc
├── .tmux.conf                   # tmux config → ~/.tmux.conf
├── .gitconfig                   # git config → ~/.gitconfig
├── alfred/
│   └── Alfred.alfredpreferences/  # → ~/Library/Application Support/Alfred/
├── vscode/
│   ├── settings.json            # → ~/Library/Application Support/Code/User/
│   ├── keybindings.json         # → ~/Library/Application Support/Code/User/
│   └── extensions.txt           # Installed via `code --install-extension`
├── positron/
│   └── settings.json            # → ~/Library/Application Support/Positron/User/
├── zotero/
│   ├── user.js                  # Preferences (copied to Zotero profile)
│   └── extensions/              # .xpi plugins (Better BibTeX excluded — see above)
├── iterm2/
│   ├── profile.plist            # Readable preferences
│   └── com.googlecode.iterm2.plist
├── pandoc/
│   └── templates/               # → ~/.local/share/pandoc/templates/ (whole dir)
└── oh-my-zsh-custom/
    ├── plugins/
    │   ├── zsh-autosuggestions/     (submodule)
    │   ├── zsh-syntax-highlighting/ (submodule)
    │   └── fzf-tab/                 (submodule)
    └── themes/
        └── dracula/                 (submodule)
```

---

## iTerm2

The iTerm2 profile is copied (not symlinked) because iTerm2 doesn't support symlinked plists reliably.

To import on a new machine:
```bash
cp ~/.dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
```
Then restart iTerm2.

---

## Troubleshooting

**Plugins not loading**
```bash
cd ~/.dotfiles && git submodule update --init --recursive
```

**Symlinks not set up correctly**
```bash
ls -la ~ | grep "\->"
ls -la ~/.oh-my-zsh/custom/plugins/
```

**Zotero preferences not applying**
Make sure `user.js` is in the right profile directory. Zotero applies it at every startup:
```bash
find ~/Library/Application\ Support/Zotero/Profiles -name "*.default" -type d
# copy user.js into that directory
```

---

## License

MIT — feel free to use and adapt.
