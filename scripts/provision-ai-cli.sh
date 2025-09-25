#!/usr/bin/env bash

set -e

echo "Provisioning AI CLI tools..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Ollama
if ! command_exists ollama; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "Ollama installed successfully."
else
    echo "Ollama is already installed."
fi

# Install Claude CLI (if available)
if ! command_exists claude; then
    echo "Installing Claude CLI..."
    if command_exists npm; then
        npm install -g @anthropic-ai/claude-cli
        echo "Claude CLI installed successfully."
    else
        echo "npm not found. Please install Node.js first."
    fi
else
    echo "Claude CLI is already installed."
fi

# Install OpenAI CLI
if ! command_exists openai; then
    echo "Installing OpenAI CLI..."
    if command_exists pip3; then
        pip3 install --user openai-cli
        echo "OpenAI CLI installed successfully."
    else
        echo "pip3 not found. Please install Python3 first."
    fi
else
    echo "OpenAI CLI is already installed."
fi

# Install GitHub Copilot CLI
if ! command_exists gh; then
    echo "GitHub CLI not found. Installing..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
fi

if command_exists gh; then
    echo "Installing GitHub Copilot CLI extension..."
    gh extension install github/gh-copilot
    echo "GitHub Copilot CLI installed successfully."
fi

echo "AI CLI tools provisioning complete!"
echo "Available tools:"
command_exists ollama && echo "  - Ollama"
command_exists claude && echo "  - Claude CLI"
command_exists openai && echo "  - OpenAI CLI"
command_exists gh && gh extension list | grep -q copilot && echo "  - GitHub Copilot CLI"