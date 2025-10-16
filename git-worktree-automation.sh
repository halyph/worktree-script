#!/bin/bash

# =============================================================================
# Git Worktree Automation Script
# =============================================================================
# This script provides automated git worktree creation and management
# Add this to your ~/.zshrc file to enable the wt, wt-list, and wt-remove commands
#
# Author: Claude Code Assistant
# Usage: wt <branch-name>
# =============================================================================

# -----------------------------------------------------------------------------
# Main Function: wt (Worktree)
# -----------------------------------------------------------------------------
# Creates a git worktree in a sibling directory named "{project}_worktrees"
#
# How it works:
# 1. Validates we're in a git repository
# 2. Gets the current project name and determines the worktrees directory
# 3. Checks if the branch exists locally, remotely, or needs to be created
# 4. Creates the worktree and navigates to it
#
# Example: If you're in "myproject" and run "wt feature-1"
# Result: Creates "myproject_worktrees/feature-1" and cd's into it
# -----------------------------------------------------------------------------
wt() {
    # Validate input parameters
    if [[ -z "$1" ]]; then
        echo "❌ Error: Branch name is required"
        echo "Usage: wt <branch-name>"
        echo "Example: wt feature-1"
        return 1
    fi

    local branch_name="$1"

    # Verify we're in a git repository by checking for .git directory
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Error: Not in a git repository"
        echo "Please run this command from within a git repository"
        return 1
    fi

    # Get the root directory of the current git repository
    # This ensures we work with the project name, not a subdirectory
    local git_root=$(git rev-parse --show-toplevel)
    local current_dir=$(basename "$git_root")
    local parent_dir=$(dirname "$git_root")

    # Construct the worktrees directory path
    # Format: {parent_directory}/{project_name}_worktrees
    local worktrees_dir="${parent_dir}/${current_dir}_worktrees"
    local worktree_path="${worktrees_dir}/${branch_name}"

    echo "🔍 Project: $current_dir"
    echo "📁 Worktrees directory: $worktrees_dir"
    echo "🎯 Target worktree: $worktree_path"

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
        echo "ℹ️  Worktree already exists at: $worktree_path"
        echo "📂 Navigating to existing worktree..."
        cd "$worktree_path"
        echo "📍 Current location: $(pwd)"
        echo "🌿 Current branch: $(git branch --show-current)"
        return 0
    fi

    # Create the worktrees directory if it doesn't exist
    echo "📁 Creating worktrees directory if needed..."
    mkdir -p "$worktrees_dir"

    # Determine if the branch exists and where
    local branch_exists=false
    local branch_location=""

    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        branch_exists=true
        branch_location="local"
        echo "✅ Found existing local branch: $branch_name"
    # Check if branch exists on remote (origin)
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        branch_exists=true
        branch_location="remote"
        echo "✅ Found existing remote branch: origin/$branch_name"
    else
        echo "🆕 Branch '$branch_name' not found. Will create new branch from current HEAD."
    fi

    # Create the worktree based on branch existence
    echo "⚙️  Creating worktree at: $worktree_path"

    if $branch_exists; then
        # Create worktree from existing branch (local or remote)
        if git worktree add "$worktree_path" "$branch_name" 2>/dev/null; then
            echo "✅ Worktree created successfully from existing branch!"
        else
            echo "❌ Failed to create worktree from existing branch"
            echo "This might happen if the branch is already checked out elsewhere"
            return 1
        fi
    else
        # Create worktree with new branch from current HEAD
        if git worktree add -b "$branch_name" "$worktree_path" 2>/dev/null; then
            echo "✅ Worktree created successfully with new branch!"
        else
            echo "❌ Failed to create worktree with new branch"
            echo "Check if the branch name is valid and try again"
            return 1
        fi
    fi

    # Navigate to the new worktree directory
    echo "🚀 Navigating to worktree directory..."
    cd "$worktree_path"

    # Display success information
    echo ""
    echo "🎉 Worktree setup complete!"
    echo "📍 Current location: $(pwd)"
    echo "🌿 Current branch: $(git branch --show-current)"
    echo "💡 Use 'wt-list' to see all worktrees or 'wt-remove $branch_name' to remove this one"
}

# -----------------------------------------------------------------------------
# Helper Function: wt-list
# -----------------------------------------------------------------------------
# Lists all git worktrees for the current repository
# Shows the path, branch, and commit for each worktree
# -----------------------------------------------------------------------------
wt-list() {
    # Verify we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Error: Not in a git repository"
        return 1
    fi

    echo "📋 Git worktrees for $(basename "$(git rev-parse --show-toplevel)"):"
    echo ""

    # Use git worktree list with nice formatting
    git worktree list --porcelain | while IFS= read -r line; do
        if [[ $line == worktree* ]]; then
            worktree_path=$(echo "$line" | cut -d' ' -f2-)
            echo "📁 $(basename "$worktree_path"): $worktree_path"
        elif [[ $line == branch* ]]; then
            branch_name=$(echo "$line" | cut -d' ' -f2- | sed 's|refs/heads/||')
            echo "   🌿 Branch: $branch_name"
        elif [[ $line == HEAD* ]]; then
            commit_hash=$(echo "$line" | cut -d' ' -f2)
            echo "   📝 Commit: ${commit_hash:0:8}"
            echo ""
        fi
    done
}

# -----------------------------------------------------------------------------
# Helper Function: wt-remove
# -----------------------------------------------------------------------------
# Removes a git worktree by branch name
# Safely removes both the worktree and cleans up git references
#
# Usage: wt-remove <branch-name>
# Example: wt-remove feature-1
# -----------------------------------------------------------------------------
wt-remove() {
    # Validate input parameters
    if [[ -z "$1" ]]; then
        echo "❌ Error: Branch name is required"
        echo "Usage: wt-remove <branch-name>"
        echo "Example: wt-remove feature-1"
        return 1
    fi

    local branch_name="$1"

    # Verify we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Error: Not in a git repository"
        return 1
    fi

    # Get the expected worktree path
    local git_root=$(git rev-parse --show-toplevel)
    local current_dir=$(basename "$git_root")
    local parent_dir=$(dirname "$git_root")
    local worktree_path="${parent_dir}/${current_dir}_worktrees/${branch_name}"

    echo "🔍 Looking for worktree: $worktree_path"

    # Check if the worktree directory exists
    if [[ ! -d "$worktree_path" ]]; then
        echo "❌ Worktree not found: $worktree_path"
        echo "💡 Use 'wt-list' to see available worktrees"
        return 1
    fi

    # Confirm removal (optional safety check)
    echo "⚠️  About to remove worktree: $worktree_path"
    echo "🌿 Branch: $branch_name"

    # Remove the worktree using git command
    # This safely removes the worktree and cleans up git references
    if git worktree remove "$worktree_path" 2>/dev/null; then
        echo "✅ Worktree removed successfully!"
        echo "📁 Removed: $worktree_path"

        # Check if the worktrees directory is now empty and remove it
        local worktrees_dir="${parent_dir}/${current_dir}_worktrees"
        if [[ -d "$worktrees_dir" ]] && [[ -z "$(ls -A "$worktrees_dir")" ]]; then
            rmdir "$worktrees_dir"
            echo "🧹 Cleaned up empty worktrees directory"
        fi
    else
        echo "❌ Failed to remove worktree"
        echo "💡 The worktree might be currently in use or have uncommitted changes"
        echo "💡 Try 'git worktree remove --force $worktree_path' if you're sure"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Installation Instructions
# -----------------------------------------------------------------------------
echo "📋 Git Worktree Automation Script Loaded!"
echo ""
echo "Available commands:"
echo "  wt <branch-name>    - Create and switch to a new worktree"
echo "  wt-list             - List all worktrees"
echo "  wt-remove <branch>  - Remove a worktree"
echo ""
echo "Example usage:"
echo "  wt feature-1        - Creates myproject_worktrees/feature-1"
echo "  wt bugfix/issue-123 - Creates myproject_worktrees/bugfix/issue-123"
echo "  wt-list             - Shows all current worktrees"
echo "  wt-remove feature-1 - Removes the feature-1 worktree"
echo ""
echo "💡 To add to your shell permanently, add this script to your ~/.zshrc file"