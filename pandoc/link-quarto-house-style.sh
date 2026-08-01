#!/usr/bin/env bash
# link-quarto-house-style.sh — wire the kinan house style into a Quarto
# project. Quarto only resolves extensions from a project-local
# `_extensions/` folder (no global lookup), so every project that wants
# format: kinan-revealjs / kinan-html / kinan-pdf needs this symlink.
#
# Usage: run from the project directory (or pass it as $1).
set -euo pipefail

target_dir="${1:-.}"
mkdir -p "$target_dir/_extensions"
ln -sfn "/Users/kinelhu/.dotfiles/pandoc/themes/kinan" "$target_dir/_extensions/kinan"
echo "Linked $target_dir/_extensions/kinan -> ~/.dotfiles/pandoc/themes/kinan"
echo "Use in frontmatter: format: kinan-revealjs | kinan-html | kinan-pdf"
