#!/usr/bin/env bash

mkdir -p ~/bin

set -e

env=prod
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            env="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ "$env" != "dev" && "$env" != "ppe" && "$env" != "prod" ]]; then
    echo "Invalid environment: $env. Allowed values are dev, ppe, and prod."
    exit 1
fi

echo "Downloading the devtunnel CLI..."

ARCH="$(uname -m)"
OS="$(uname)"

if [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        URL="https://tunnelsassets$env.blob.core.windows.net/cli/osx-arm64-devtunnel"
    elif [[ "$ARCH" == "x86_64" ]]; then
        URL="https://tunnelsassets$env.blob.core.windows.net/cli/osx-x64-devtunnel"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
elif [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
        URL="https://tunnelsassets$env.blob.core.windows.net/cli/linux-arm64-devtunnel"
    elif [[ "$ARCH" == "x86_64" ]]; then
        URL="https://tunnelsassets$env.blob.core.windows.net/cli/linux-x64-devtunnel"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
    
    # Detecting Linux distribution to install dependencies
    if command -v apt-get > /dev/null; then
        sudo apt-get -qq update
        sudo apt-get -qq install -y libsecret-1-0
    elif command -v dnf > /dev/null; then
        sudo dnf -y install libsecret
    else
        echo "Unsupported package manager. Please install libsecret manually."
        exit 1
    fi
else
    echo "Unsupported OS: $OS"
    exit 1
fi

curl -sL -o ~/bin/devtunnel $URL || { echo "Cannot install CLI. Aborting."; exit 1; }
chmod +x ~/bin/devtunnel

# Determine the current shell and update the appropriate configuration file
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
    echo "Added $HOME/bin to PATH in $SHELL_CONFIG"
fi

# Add alias to the shell configuration
if ! grep -q 'alias tunnel=' "$SHELL_CONFIG"; then
    echo 'alias tunnel="devtunnel"' >> "$SHELL_CONFIG"
    echo "Added alias 'tunnel' to $SHELL_CONFIG"
fi

# Source the updated shell configuration
source "$SHELL_CONFIG"

echo "devtunnel CLI installed!"
echo "Version: $(~/bin/devtunnel --version)"
echo "To get started, run: tunnel -h"
