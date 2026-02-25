#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.dotfiles"

cd "$DOTFILES_DIR"

echo -e "${BLUE}🔄 Capturing latest app state...${NC}"

# Brewfile
if command -v brew &>/dev/null; then
    brew bundle dump --file="$DOTFILES_DIR/Brewfile" --force --quiet
    echo -e "${GREEN}✓ Brewfile updated${NC}"
fi

# VS Code extensions
if command -v code &>/dev/null; then
    code --list-extensions > "$DOTFILES_DIR/vscode/extensions.txt"
    echo -e "${GREEN}✓ VS Code extensions updated${NC}"
fi

# iTerm2 preferences (only if iTerm2 is installed)
if defaults read com.googlecode.iterm2 &>/dev/null 2>&1; then
    defaults read com.googlecode.iterm2 > "$DOTFILES_DIR/iterm2/profile.plist"
    cp ~/Library/Preferences/com.googlecode.iterm2.plist "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist"
    echo -e "${GREEN}✓ iTerm2 preferences updated${NC}"
fi

echo ""

# Check if there are any changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Changes detected:${NC}"
    git status -s
    echo ""

    git add .

    echo -e "${GREEN}Enter commit message (or press Enter for default):${NC}"
    read -r commit_msg

    if [[ -z "$commit_msg" ]]; then
        commit_msg="Update dotfiles — $(date '+%Y-%m-%d')"
    fi

    git commit -m "$commit_msg"
    echo -e "${GREEN}✓ Changes committed${NC}"
else
    echo -e "${GREEN}✓ No changes to commit${NC}"
fi

# Push if ahead of remote
if [[ -n $(git log @{u}.. 2>/dev/null) ]]; then
    echo -e "${BLUE}📤 Pushing to remote...${NC}"
    git push
    echo -e "${GREEN}✓ Pushed to GitHub${NC}"
else
    echo -e "${GREEN}✓ Already up to date with remote${NC}"
fi

# Check for remote updates
git fetch --quiet
if [[ -n $(git log ..@{u} 2>/dev/null) ]]; then
    echo -e "${YELLOW}⚠ Remote has updates. Run 'git pull' to sync.${NC}"
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
