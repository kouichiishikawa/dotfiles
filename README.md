# dotfiles

My personal dotfiles for development environment setup.

## Installation

```bash
git clone git@github.com:kouichiishikawa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
What's included

.zshrc - Zsh shell configuration
.zprofile - Login shell configuration
.gitconfig - Git configuration
.ssh/config - SSH configuration (public settings only)

Features

Automatic backup of existing dotfiles
Homebrew installation check
Safe installation with error handling
Colored output for better visibility
Test script for verification

Requirements

Git
macOS
Zsh

Directory Structure
Copy.
├── .gitignore
├── .zshrc
├── .zprofile
├── .ssh/
│   └── config
├── install.sh
└── test.sh
