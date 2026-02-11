#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.dotfiles"

cd "$DOTFILES_DIR"

echo -e "${BLUE}🔄 Syncing dotfiles...${NC}"

# Check if there are any changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Changes detected:${NC}"
    git status -s
    echo ""

    # Show diff
    echo -e "${YELLOW}📋 Diff:${NC}"
    git diff --stat
    echo ""

    # Add all changes
    git add .

    # Prompt for commit message
    echo -e "${GREEN}Enter commit message (or press Enter for default):${NC}"
    read -r commit_msg

    if [[ -z "$commit_msg" ]]; then
        commit_msg="Update dotfiles configuration"
    fi

    # Commit
    git commit -m "$commit_msg"
    echo -e "${GREEN}✓ Changes committed${NC}"
else
    echo -e "${GREEN}✓ No changes to commit${NC}"
fi

# Check if we're ahead of remote
if [[ -n $(git log @{u}.. 2>/dev/null) ]]; then
    echo -e "${BLUE}📤 Pushing to remote...${NC}"
    git push
    echo -e "${GREEN}✓ Pushed to GitHub${NC}"
else
    echo -e "${GREEN}✓ Already up to date with remote${NC}"
fi

# Check for remote updates
echo -e "${BLUE}📥 Checking for remote updates...${NC}"
git fetch

if [[ -n $(git log ..@{u} 2>/dev/null) ]]; then
    echo -e "${YELLOW}⚠ Remote has updates. Run 'git pull' to sync.${NC}"
else
    echo -e "${GREEN}✓ No remote updates${NC}"
fi

echo ""
echo -e "${GREEN}✅ Sync complete!${NC}"
