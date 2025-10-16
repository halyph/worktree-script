# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Git Worktree Automation Script** that provides shell functions for creating and managing Git worktrees. The main functionality is contained in a single bash script (`git-worktree-automation.sh`) that users source into their shell environment.

**Core Purpose**: Automate the creation of Git worktrees in organized directory structures to enable working on multiple branches simultaneously without the overhead of multiple repository clones.

## Key Commands

### Development Commands
- **No build system**: This is a pure shell script with no compilation or build steps required
- **No test suite**: The script relies on manual testing in shell environments
- **No linting**: Standard shell script without automated code quality tools

### Script Testing
```bash
# Source the script for testing
source git-worktree-automation.sh

# Test the main functions
wt test-branch          # Create a test worktree
wt-list                 # Verify worktree creation
wt-remove test-branch   # Clean up test worktree
```

### Installation Testing
```bash
# Test different installation methods
cat git-worktree-automation.sh >> ~/.zshrc  # Method 1
source ~/.config/git-worktree-automation.sh # Method 2
ln -s "$(pwd)/git-worktree-automation.sh" ~/.config/  # Method 3
```

## Architecture

### Single-File Design
The entire functionality is contained in `git-worktree-automation.sh` with three main functions:

- **`wt(branch-name)`**: Core worktree creation and navigation
- **`wt-list()`**: Lists all worktrees with details
- **`wt-remove(branch-name)`**: Safe worktree removal and cleanup

### Directory Structure Pattern
```
parent-directory/
├── myproject/                    # Original repository
└── myproject_worktrees/          # Generated worktrees directory
    ├── feature-1/                # Individual worktrees
    ├── bugfix-123/
    └── release-v2.1.0/
```

### Branch Detection Logic
The script prioritizes branches in this order:
1. **Local branches** (`refs/heads/branch-name`)
2. **Remote branches** (`refs/remotes/origin/branch-name`)
3. **New branches** (created from current HEAD)

### Key Implementation Details

**Path Resolution**: Uses `git rev-parse --show-toplevel` to work from repository root, not current subdirectory.

**Safety Features**:
- Git repository validation before any operations
- Existing worktree detection and reuse
- Comprehensive error handling with helpful messages
- Automatic cleanup of empty worktree directories

**Remote Branch Support**: Automatically detects and creates worktrees from remote branches after `git fetch`, enabling team collaboration workflows.

## File Structure

- **`git-worktree-automation.sh`** (240 lines): Complete script with all functions and installation messages
- **`README.md`**: Comprehensive documentation with installation methods, usage examples, and troubleshooting

## Installation Methods

The script supports three installation approaches detailed in the README:
1. **Direct append** to `~/.zshrc` (simplest)
2. **Source method** with separate config file
3. **Symlink method** (best for development) - enables easy updates via `git pull`

## Team Workflow Integration

The script is designed for team environments where developers need to:
- Quickly switch between feature branches
- Work on colleague's remote branches
- Handle hotfixes and release branches
- Review pull requests in isolated worktrees

**Critical Requirement**: Remote branches must be fetched locally (`git fetch`) before the script can detect and use them.

## Troubleshooting Notes

**Common Issues**:
- "Not in a git repository" - Ensure running from within a git repo
- "Failed to create worktree" - Branch may already be checked out elsewhere
- Remote branch not found - Run `git fetch` first to sync remote references

**Manual Cleanup**: If worktrees become corrupted, use `git worktree list` and `git worktree remove --force` for recovery.