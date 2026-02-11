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
create_symlink "$DOTFILES_DIR/pandoc/header.tex" "$HOME/.local/share/pandoc/templates/header.tex"

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

# iTerm2 profile import instructions
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
echo "🔧 Optional dependencies to install:"
echo "   brew install fzf zoxide tmux"
echo ""
