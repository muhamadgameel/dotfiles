#!/usr/bin/env bash

# Exit on any error
set -e

# Dock settings
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock tilesize -int 46
defaults write com.apple.dock largesize -int 64

# Set Dark Mode using AppleScript
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'