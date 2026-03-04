# 🧹 gitkeeper

**The git branch cleanup tool that keeps your repository tidy**

Safe, intelligent, and interactive Git branch management for macOS (and Unix-like systems).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![macOS](https://img.shields.io/badge/macOS-✓-blue)
![Linux](https://img.shields.io/badge/Linux-✓-blue)

---

## 💭 Why gitkeeper?

Your git repository gets messy. It happens:

- ✗ Merged feature branches clutter your branch list
- ✗ Stale branches from abandoned work pile up
- ✗ Upstream branches vanish but leave local ghosts
- ✗ You're afraid to delete anything (what if you need it?)

**gitkeeper** detects and safely removes these branches—with your explicit confirmation. Every deletion is logged for recovery.

```bash
$ gitkeeper
🌿 gitkeeper - Safe branch cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Cleanup Summary:
  Total branches to review: 7
  📌 Merged: 4
  ⏰ Stale (>30d): 2
  ❌ Upstream gone: 1

[fzf interactive selection]

✅ Deleted: 7
```

---
### Install via curl (one-liner)

You can install gitkeeper directly with a single curl command. Review the script before running if you prefer:

```bash
curl -LsSf https://raw.githubusercontent.com/tukuyomil032/GitKeeper/refs/heads/main/install.sh | sh
```

---
## 🚀 Quick Start

### macOS (Intel & Apple Silicon)

```bash
# Clone the repository
git clone https://github.com/tukuyomil322/gitkeeper.git
cd gitkeeper

# Install dependencies
brew install jq  # if not already installed
brew install fzf # (optional, for enhanced interactive UI)

# Run installer
./scripts/install-macos.sh
```

### Linux

```bash
# Clone the repository
git clone https://github.com/tukuyomil322/gitkeeper.git
cd gitkeeper

# Install dependencies
brew install jq     # or use your distro package manager
# fzf is optional for enhanced interactive selection
brew install fzf

# Run installer (if provided for your platform)
./scripts/install-macos.sh  # installer currently targets macOS; see repo scripts
```

### From Source (Development)

```bash
git clone https://github.com/tukuyomil322/gitkeeper.git
cd gitkeeper

# Make installer executable
chmod +x ./scripts/install-macos.sh
chmod +x ./scripts/setup-alias.sh

# Run installer
./scripts/install-macos.sh

# Setup shell alias (optional)
./scripts/setup-alias.sh zsh    # or bash
```

---

## 📖 Usage

### Basic Cleanup

```bash
# Interactive: review branch recommendations
gitkeeper

# Quick alias (installed by default)
gk

# Preview without deleting
gitkeeper --dry-run

# Force delete unmerged branches (⚠️)
gitkeeper --force
```

### With Options

The CLI supports both long and short options. Notable options and behavior changes:

- `--directory, -d DIR` : Specify directory to scan (accepts relative paths and `~` expansion).
- `--since, -s DAYS` : Override stale threshold for the run.
- `--protect, -p BRANCH` : Add a protected branch (can be repeated).
- `--dry-run, -n` : Show what would be deleted without deleting.
- `--force, -f` : Force delete (use with caution).
- `--configure, -C` : Interactive config editor that writes `config.json`.

Examples:

```bash
# Use 45 days threshold instead of default 30
gitkeeper --since 45

# Disable certain checks
gitkeeper --no-stale       # Don't check for old branches
gitkeeper --no-merged      # Skip merged check
gitkeeper --no-gone        # Skip upstream gone check

# Add exceptions
gitkeeper --protect staging  # Don't delete 'staging'
gitkeeper --protect hotfix-*  # (exact match)
```

### Multi-Repository Scanning

You can point gitkeeper at a directory (absolute or relative) to scan multiple repositories. The option is `--directory` (short `-d`) and accepts `~` expansion and relative paths.

When multiple repositories are found, gitkeeper presents an interactive selection (fzf if available, numbered menu otherwise). Example:

```bash
# Scan relative path
gitkeeper -d ./projects

# Scan with tilde expansion
gitkeeper --directory ~/workspace
```

If you run `gitkeeper` without any options while not inside a git repo, it will prompt you interactively for the directory to scan (relative path allowed), stale threshold, and protected branches for that single run.

When multiple repositories are found, gitkeeper presents an interactive selection (fzf if available, numbered menu otherwise).

### Advanced Examples

```bash
# Clean before release: dry-run + force
gitkeeper --dry-run --force

# Aggressive cleanup with custom threshold
gitkeeper --since 60 --no-stale --force

# Check stale branches only
gitkeeper --no-merged --no-gone
```

---

## 🔧 Configuration

Edit `~/.config/gitkeeper/config.json` to set defaults:

```json
{
  "protected": ["main", "master", "develop", "staging"],
  "days": 30,
  "checkMerged": true,
  "checkStale": true,
  "checkUpstreamGone": true,
  "defaultBranch": "main"
}
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `protected` | array | `["main", "master", "develop"]` | Branches that are never deleted |
| `days` | number | `30` | Stale threshold in days |
| `checkMerged` | bool | `true` | Detect merged branches |
| `checkStale` | bool | `true` | Detect branches not updated in N days |
| `checkUpstreamGone` | bool | `true` | Detect branches with deleted upstreams |
| `defaultBranch` | string | `"main"` | Default branch for merge detection |

---

## 🎯 What gitkeeper Detects

### 1. **Merged Branches** 🌿
Already merged into your default branch (safe to delete)

```bash
$ git branch -d feature/old-ui
# ✓ Deleted (was merged)
```

### 2. **Stale Branches** ⏰
No commits for 30+ days (configurable)

```bash
$ git log --oneline feature/old-feature | head -1
# Last commit: 45 days ago → marked for cleanup
```

### 3. **Upstream Gone** ❌
Remote tracking branch was deleted but local remains

```bash
$ git branch -vv
# feature/old-pr [origin/feature/old-pr: gone]
```

---

## 💾 Recovery

Every deletion is logged. Restore any branch:

```bash
# Find the commit hash
$ cat .git/gitkeeper-backup/20240304-143022.log
feature/old-ui | abc1234567... | 2024-03-04 14:30:22 +0900

# Restore
$ git branch feature/old-ui abc1234567
# ✓ Branch restored
```

---

## 🛠️ Dependencies

### Required
- `git` - version control
- `jq` - JSON query (install: `brew install jq`)

### Recommended  
- `fzf` - interactive UI (install: `brew install fzf`)
  - Without it: simple numbered selection menu

### Platform Support
- ✅ macOS (Intel & Apple Silicon)

---

## 📊 Features

✅ Safe deletion with confirmation  
✅ Backup logging for recovery  
✅ Interactive multi-select (fzf)  
✅ Diff preview before delete  
✅ GitHub PR link detection  
✅ Configurable filters  
✅ Dry-run mode  
✅ Force delete option  
✅ zsh completions  
✅ Multi-repository scanning  

---

## 🔨 Development

### Requirements
- bash / zsh
- ShellCheck (for linting)

### Build & Test

```bash
# Lint scripts
make lint

# Run tests
make test

# Create release
make release VERSION=1.0.0
```

### Contributing

Bug reports & PRs welcome! Please follow:
- ShellCheck linting (`make lint`)
- Commit messages with clear purpose
- Test on both macOS and Windows if possible
 - Test on macOS and Linux if possible

---

## 🎯 Commands Reference

```bash
gitkeeper                      # Interactive cleanup
gk                            # Quick alias shortcut
gitkeeper --help              # Show help
gitkeeper --directory ~/repos  # Scan and select repository (accepts relative paths)
gitkeeper -d ./projects        # Short form
gitkeeper --dry-run           # Preview changes
gitkeeper --force             # Force delete unmerged
gitkeeper --since 45          # Use 45-day threshold
gitkeeper --protect staging   # Add protected branch
gitkeeper --no-merged         # Skip merged check
gitkeeper --no-stale          # Skip stale check
gitkeeper --no-gone           # Skip upstream gone check
gitkeeper --configure         # Interactive config editor (writes config.json)
```

---

## ⚡ Quick Alias Setup

The `gk` command is installed by default as a symlink. To add it to your shell profile:

```bash
# For zsh (recommended)
./setup-alias.sh zsh
source ~/.zshrc

# For bash
./setup-alias.sh bash
source ~/.bash_profile

# Or manually add to ~/.zshrc or ~/.bash_profile:
alias gk='gitkeeper'
```

Then use:

```bash
gk                  # Same as gitkeeper
gk --dry-run       # Preview
gk --since 45 --no-stale  # Complex operations
```

---

## 🔄 Uninstalling

```bash
make uninstall
rm -f ~/.config/gitkeeper/config.json
rm -f ~/.zsh/completions/_gitkeeper
```

---

## 🛠️ Development & CI/CD

### Local Testing

```bash
make lint        # Run ShellCheck
make test        # Run tests (requires git)
make clean       # Remove build artifacts
```

### GitHub Actions Workflows

gitkeeper includes comprehensive CI/CD:

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| **CI** | ShellCheck, config validation, multi-OS tests | push, PR |
| **Code Quality** | Extended analysis and structure checks | push, PR |
| **Security** | Secrets scanning and safety checks | push, PR |
| **Release** | Validation, builds, GitHub Release creation | tag v* |

All workflows must pass before merging to main.

---

## 📄 License

MIT License - see LICENSE file for details

---

## 💬 Support

- **Questions?** Open an issue on GitHub
- **Found a bug?** [Report it](https://github.com/tukuyomil322/gitkeeper/issues)
- **Have ideas?** [Discussions](https://github.com/tukuyomil322/gitkeeper/discussions)

---

**Made with ✨ for git enthusiasts who hate cluttered branch lists**

Star us on GitHub if you find gitkeeper useful! ⭐
