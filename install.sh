#!/bin/bash

set -e

echo "🚀 Starting dotfiles installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dotfiles directory
DOTFILES_DIR="$HOME/.dotfiles"

# Function to create backup
backup_file() {
    if [ -f "$1" ] || [ -L "$1" ]; then
        echo -e "${YELLOW}Backing up existing $1${NC}"
        mv "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"

    # Backup existing file/symlink
    backup_file "$target"

    # Create symlink
    ln -sf "$source" "$target"
    echo -e "${GREEN}✓ Linked $target -> $source${NC}"
}

# Check if oh-my-zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}oh-my-zsh not found. Installing...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo -e "${GREEN}✓ oh-my-zsh installed${NC}"
else
    echo -e "${GREEN}✓ oh-my-zsh already installed${NC}"
fi

# Initialize and update git submodules
echo "📦 Initializing git submodules..."
cd "$DOTFILES_DIR"
git submodule update --init --recursive
echo -e "${GREEN}✓ Submodules initialized${NC}"

# Create symlinks for config files
echo "🔗 Creating symlinks..."
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/pandoc/templates" "$HOME/.local/share/pandoc/templates"

# Alfred preferences (macOS only)
if [ -d "$HOME/Library/Application Support/Alfred" ]; then
    create_symlink "$DOTFILES_DIR/alfred/Alfred.alfredpreferences" "$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences"
else
    echo -e "${YELLOW}Alfred not found — skipping Alfred preferences link${NC}"
fi

# VS Code settings
if [ -d "$HOME/Library/Application Support/Code/User" ]; then
    create_symlink "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    create_symlink "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
else
    echo -e "${YELLOW}VS Code not found — skipping VS Code settings link${NC}"
fi

# Positron settings
if [ -d "$HOME/Library/Application Support/Positron/User" ]; then
    create_symlink "$DOTFILES_DIR/positron/settings.json" "$HOME/Library/Application Support/Positron/User/settings.json"
else
    echo -e "${YELLOW}Positron not found — skipping Positron settings link${NC}"
fi

# Zotero plugins and user preferences
ZOTERO_PROFILE=$(find "$HOME/Library/Application Support/Zotero/Profiles" -maxdepth 1 -name "*.default" -type d 2>/dev/null | head -1)
if [ -n "$ZOTERO_PROFILE" ]; then
    echo "📚 Installing Zotero plugins..."
    mkdir -p "$ZOTERO_PROFILE/extensions"
    # Copy small bundled plugins
    for xpi in "$DOTFILES_DIR/zotero/extensions/"*.xpi; do
        cp "$xpi" "$ZOTERO_PROFILE/extensions/"
        echo -e "${GREEN}✓ $(basename "$xpi")${NC}"
    done
    # Install user.js preferences
    cp "$DOTFILES_DIR/zotero/user.js" "$ZOTERO_PROFILE/user.js"
    echo -e "${GREEN}✓ Zotero user.js preferences installed${NC}"
    echo -e "${YELLOW}Note: Download Better BibTeX manually from https://github.com/retorquere/zotero-better-bibtex/releases${NC}"
    echo -e "${YELLOW}Note: Update machine-specific paths in $DOTFILES_DIR/zotero/user.js${NC}"
else
    echo -e "${YELLOW}Zotero not found — skipping Zotero setup${NC}"
fi

# Create symlinks for oh-my-zsh custom plugins and themes
echo "🔌 Linking oh-my-zsh custom plugins and themes..."
create_symlink "$DOTFILES_DIR/oh-my-zsh-custom/plugins/zsh-autosuggestions" "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
create_symlink "$DOTFILES_DIR/oh-my-zsh-custom/plugins/zsh-syntax-highlighting" "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
create_symlink "$DOTFILES_DIR/oh-my-zsh-custom/plugins/fzf-tab" "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
create_symlink "$DOTFILES_DIR/oh-my-zsh-custom/themes/dracula" "$HOME/.oh-my-zsh/custom/themes/dracula"

# Check for dependencies
echo "🔍 Checking dependencies..."

# Check for fzf
if ! command -v fzf &> /dev/null; then
    echo -e "${YELLOW}fzf not found. Install with: brew install fzf${NC}"
else
    echo -e "${GREEN}✓ fzf installed${NC}"
fi

# Check for zoxide
if ! command -v zoxide &> /dev/null; then
    echo -e "${YELLOW}zoxide not found. Install with: brew install zoxide${NC}"
else
    echo -e "${GREEN}✓ zoxide installed${NC}"
fi

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo -e "${YELLOW}tmux not found. Install with: brew install tmux${NC}"
else
    echo -e "${GREEN}✓ tmux installed${NC}"
fi

# Homebrew packages
echo ""
echo "🍺 Homebrew packages..."
if command -v brew &> /dev/null; then
    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        echo "Installing packages from Brewfile (this may take a while)..."
        brew bundle install --file="$DOTFILES_DIR/Brewfile"
        echo -e "${GREEN}✓ Homebrew packages installed${NC}"
    fi
else
    echo -e "${YELLOW}Homebrew not found. Install it first:${NC}"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo "  Then re-run this script."
fi

# VS Code extensions
echo ""
if command -v code &> /dev/null && [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
    echo "📦 Installing VS Code extensions..."
    while IFS= read -r ext; do
        code --install-extension "$ext" --force &>/dev/null && echo -e "${GREEN}✓ $ext${NC}" || echo -e "${YELLOW}⚠ $ext (failed)${NC}"
    done < "$DOTFILES_DIR/vscode/extensions.txt"
else
    echo -e "${YELLOW}VS Code CLI not found — skipping extension install${NC}"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. For iTerm2:"
echo "   - Open iTerm2 preferences (Cmd+,)"
echo "   - Go to Profiles → Other Actions → Import JSON Profiles"
echo "   - Select: $DOTFILES_DIR/iterm2/profile.plist"
echo "   - Or copy the plist file to ~/Library/Preferences/com.googlecode.iterm2.plist"
echo ""
