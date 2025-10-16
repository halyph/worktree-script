# Git Worktree Automation Script

An automated git worktree creation and management system that creates worktrees in a structured directory outside your main project.

## Features

- 🚀 **One-command worktree creation**: `wp feature-1` creates and switches to the worktree
- 📁 **Organized structure**: Worktrees stored in `{project}_worktrees/` directory
- 🌿 **Smart branch handling**: Works with existing local/remote branches or creates new ones
- ♻️ **Reuse existing worktrees**: Navigates to existing worktrees instead of failing
- 🛡️ **Comprehensive error handling**: Clear messages for all edge cases
- 🧹 **Easy cleanup**: Remove worktrees with `wpremove` command

## Installation

### Method 1: Add to .zshrc (Recommended)

1. Copy the contents of `git-worktree-automation.sh` to your `~/.zshrc` file:

```bash
# Add this to the end of your ~/.zshrc file
cat git-worktree-automation.sh >> ~/.zshrc
```

2. Reload your shell:

```bash
source ~/.zshrc
```

### Method 2: Source the script

1. Place the script in a permanent location:

```bash
cp git-worktree-automation.sh ~/.config/git-worktree-automation.sh
```

2. Add this line to your `~/.zshrc`:

```bash
source ~/.config/git-worktree-automation.sh
```

3. Reload your shell:

```bash
source ~/.zshrc
```

### Method 3: Symlink (Best for Development)

This method is ideal if you want to keep the script in this repository and easily update it:

1. Create a symlink to the script in a directory that's in your PATH or config directory:

```bash
# Option A: Link to a directory in your PATH (e.g., /usr/local/bin)
ln -s "$(pwd)/git-worktree-automation.sh" /usr/local/bin/git-worktree-automation.sh

# Option B: Link to your config directory
mkdir -p ~/.config
ln -s "$(pwd)/git-worktree-automation.sh" ~/.config/git-worktree-automation.sh
```

2. Add this line to your `~/.zshrc`:

```bash
# If you used Option A (PATH directory)
source /usr/local/bin/git-worktree-automation.sh

# If you used Option B (config directory)
source ~/.config/git-worktree-automation.sh
```

3. Reload your shell:

```bash
source ~/.zshrc
```

**Benefits of the symlink method:**
- ✅ Easy updates - just `git pull` in this repository
- ✅ Version control - track changes to your automation script
- ✅ Portability - works across multiple machines with the same setup
- ✅ Clean separation - keeps your `.zshrc` minimal

## Usage

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `wp <branch-name>` | Create/switch to worktree | `wp feature-1` |
| `wplist` | List all worktrees | `wplist` |
| `wpremove <branch>` | Remove a worktree | `wpremove feature-1` |

### Examples

#### Creating Worktrees

```bash
# In project "myproject"

# New branches (created from current HEAD)
wp feature-1           # Creates myproject_worktrees/feature-1
wp bugfix/issue-123    # Creates myproject_worktrees/bugfix/issue-123
wp hotfix-2024         # Creates myproject_worktrees/hotfix-2024

# Remote branches (after git fetch)
wp feature/user-auth   # Creates from origin/feature/user-auth
wp release/v2.1.0      # Creates from origin/release/v2.1.0

# Existing local branches
wp main                # Creates from local main branch
wp develop             # Creates from local develop branch
```

#### Managing Worktrees

```bash
# List all worktrees
wplist

# Output:
# 📋 Git worktrees for myproject:
#
# 📁 feature-1: /Users/you/projects/myproject_worktrees/feature-1
#    🌿 Branch: feature-1
#    📝 Commit: a1b2c3d4
#
# 📁 main: /Users/you/projects/myproject
#    🌿 Branch: main
#    📝 Commit: e5f6g7h8

# Remove a worktree
wpremove feature-1
```

## Working with Remote Branches

The script has **built-in support for remote branches**! This is perfect for team collaboration where you need to work on branches created by colleagues or switch between different remote branches quickly.

### How Remote Branch Detection Works

The script automatically detects and handles remote branches in this priority order:

1. **Local branch** (if exists) - `refs/heads/branch-name`
2. **Remote branch** (if exists) - `refs/remotes/origin/branch-name`
3. **New branch** (if neither exists) - Creates from current HEAD

### Remote Branch Examples

#### Working with Colleague's Branches

```bash
# Colleague pushed "feature/user-authentication" to origin
git fetch                                    # Get latest remote refs
wp feature/user-authentication              # Creates worktree tracking origin/feature/user-authentication

# Script output:
# ✅ Found existing remote branch: origin/feature/user-authentication
# ⚙️ Creating worktree at: myproject_worktrees/feature/user-authentication
# ✅ Worktree created successfully from existing branch!
# 🎉 Worktree setup complete!
```

#### Common Team Workflow Patterns

```bash
# Work on hotfixes
git fetch
wp hotfix/critical-security-fix             # Creates from origin/hotfix/critical-security-fix

# Review pull requests
git fetch
wp feature/new-dashboard                     # Creates from origin/feature/new-dashboard

# Work on release branches
git fetch
wp release/v2.1.0                           # Creates from origin/release/v2.1.0

# Handle complex branch names
git fetch
wp bugfix/issue-1234-payment-gateway        # Creates from origin/bugfix/issue-1234-payment-gateway
```

### Prerequisites for Remote Branches

**Important**: Remote branches must be visible locally before the script can use them.

```bash
# Always fetch first to see latest remote branches
git fetch

# Or fetch from specific remote
git fetch origin

# Verify remote branch exists
git branch -r | grep feature-name

# Then use the script
wp feature-name
```

### What Happens Behind the Scenes

When you run `wp remote-branch-name`:

1. **Detection Phase**:
   ```bash
   # Script checks in order:
   git show-ref --verify --quiet "refs/heads/remote-branch-name"      # Local first
   git show-ref --verify --quiet "refs/remotes/origin/remote-branch-name"  # Then remote
   ```

2. **Worktree Creation**:
   ```bash
   # For remote branches, git automatically:
   git worktree add myproject_worktrees/remote-branch-name remote-branch-name
   # This creates a local tracking branch automatically
   ```

3. **Automatic Tracking Setup**:
   - Creates local `remote-branch-name` branch
   - Sets up tracking to `origin/remote-branch-name`
   - Ready for commits and pushes

### Branch Priority Examples

Understanding which branch the script will use:

```bash
# Scenario 1: Only remote branch exists
git branch -r | grep feature-x              # Shows: origin/feature-x
wp feature-x                                # ✅ Uses origin/feature-x

# Scenario 2: Both local and remote exist
git branch | grep feature-y                 # Shows: feature-y
git branch -r | grep feature-y              # Shows: origin/feature-y
wp feature-y                                # ✅ Uses local feature-y (priority)

# Scenario 3: Neither exists
wp feature-z                                # ✅ Creates new branch from HEAD
```

### Team Collaboration Tips

**Daily Workflow**:
```bash
# Morning routine - sync with team
git fetch
wp feature/current-task                     # Work on your feature

# Switch to review colleague's work
git fetch
wp feature/colleague-task                   # Quick switch to review

# Switch back to your work
wp feature/current-task                     # Instantly back to your branch
```

**Multiple Remote Scenarios**:
```bash
# The script currently checks 'origin' remote
# For other remotes, fetch them first:
git fetch upstream
git fetch fork

# Then create local branch manually if needed:
git checkout -b upstream-feature upstream/feature-name
wp upstream-feature                         # Now script can use local branch
```

### Troubleshooting Remote Branches

**Branch not found**:
```bash
# ❌ Error: Branch 'feature-x' not found
git fetch                                   # Fetch latest remotes
git branch -r | grep feature               # Verify branch name
wp feature-x                               # Try again
```

**Multiple remotes conflict**:
```bash
# If you have branches with same name on different remotes
git branch -r | grep feature-name          # See all remote versions

# Create specific local branches:
git checkout -b feature-origin origin/feature-name
git checkout -b feature-upstream upstream/feature-name

# Then use script:
wp feature-origin                          # Uses your local branch
```

**Outdated remote references**:
```bash
# If remote branch was deleted but you still see it
git remote prune origin                    # Clean up stale references
git fetch                                  # Get fresh remote refs
```

## How It Works

### Directory Structure

When you run `wp feature-1` in a project called "myproject":

```
parent-directory/
├── myproject/                    # Original project
└── myproject_worktrees/          # Worktrees directory
    ├── feature-1/                # Your new worktree
    ├── bugfix-123/              # Another worktree
    └── hotfix-2024/             # Yet another worktree
```

### Branch Handling Logic

The script intelligently handles different branch scenarios:

1. **Existing Local Branch**: Creates worktree from local branch
2. **Existing Remote Branch**: Creates worktree tracking the remote branch
3. **New Branch**: Creates worktree with a new branch from current HEAD
4. **Existing Worktree**: Navigates to the existing worktree directory

### Safety Features

- ✅ Validates git repository before proceeding
- ✅ Checks for required parameters
- ✅ Handles worktree creation failures gracefully
- ✅ Prevents overwriting existing worktrees
- ✅ Provides clear error messages and suggestions
- ✅ Cleans up empty worktree directories after removal

## Script Components

### Main Functions

- **`wp()`**: Core worktree creation function
- **`wplist()`**: Lists all worktrees with details
- **`wpremove()`**: Safely removes worktrees

### Key Features Explained

#### Smart Path Resolution
```bash
# Gets the git repository root, not current subdirectory
local git_root=$(git rev-parse --show-toplevel)
local current_dir=$(basename "$git_root")
```

#### Branch Detection
```bash
# Check local branches
git show-ref --verify --quiet "refs/heads/$branch_name"

# Check remote branches
git show-ref --verify --quiet "refs/remotes/origin/$branch_name"
```

#### Safe Worktree Creation
```bash
# For existing branches
git worktree add "$worktree_path" "$branch_name"

# For new branches
git worktree add -b "$branch_name" "$worktree_path"
```

## Troubleshooting

### Common Issues

**Error: "Not in a git repository"**
- Make sure you're running the command from within a git repository
- Run `git status` to verify you're in a git repo

**Error: "Failed to create worktree"**
- The branch might already be checked out in another worktree
- Use `wplist` to see existing worktrees
- Try `wpremove <branch>` if the worktree exists but is problematic

**Error: "Worktree not found"**
- Use `wplist` to see available worktrees
- Check if you're in the correct git repository

### Manual Cleanup

If something goes wrong, you can manually clean up:

```bash
# List all worktrees
git worktree list

# Remove a problematic worktree
git worktree remove /path/to/worktree

# Or force remove if needed
git worktree remove --force /path/to/worktree
```

## Requirements

- Git 2.5+ (for `git worktree` support)
- Bash or Zsh shell
- Standard Unix utilities (basename, dirname, mkdir)

## License

This script is provided as-is for educational and productivity purposes. Feel free to modify and distribute.