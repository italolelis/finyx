---
name: finyx:update
description: Update FINYX to the latest version
allowed-tools:
  - Bash
  - Read
  - WebFetch
---

<objective>

Update FINYX to the latest version from npm and display changelog.

</objective>

<execution_context>

@~/.claude/finyx/references/disclaimer.md
@.finyx/profile.json

</execution_context>

<process>

## Step 0: Check Profile Exists

```bash
[ -f .finyx/profile.json ] || { echo "ERROR: No financial profile found. Run /finyx:profile first to set up your profile."; exit 1; }
```

## Step 1: Check Current Version

```bash
CURRENT=$(npm list -g finyx-cc --depth=0 2>/dev/null | grep finyx-cc | sed 's/.*@//')
echo "Current version: ${CURRENT:-not installed globally}"
```

Also check local installation:
```bash
[ -f ~/.claude/finyx/package.json ] && cat ~/.claude/finyx/package.json | grep '"version"'
```

## Step 2: Check Latest Version

```bash
LATEST=$(npm view finyx-cc version)
echo "Latest version: $LATEST"
```

## Step 3: Compare Versions

If current equals latest:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► ALREADY UP TO DATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You're running the latest version: v[VERSION]
```

If update available, continue to Step 4.

## Step 4: Fetch Changelog

Fetch release notes from GitHub:
```
https://api.github.com/repos/italolelis/immo/releases/latest
```

Extract and display:
- Version
- Release date
- Release notes/body

## Step 5: Update

Run the installer to update:
```bash
npx finyx-cc@latest
```

## Step 6: Confirm Update

```bash
NEW_VERSION=$(npm list -g finyx-cc --depth=0 2>/dev/null | grep finyx-cc | sed 's/.*@//')
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 FINYX ► UPDATED SUCCESSFULLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated: v[OLD] → v[NEW]

What's New in v[NEW]:
─────────────────────────────────────────────────────
[CHANGELOG CONTENT]
─────────────────────────────────────────────────────

Run /finyx:help to see available commands.
```

## Step 7: Disclaimer

Append the legal disclaimer from the loaded disclaimer.md reference at the end of this output.

</process>

<error_handling>

- **npm not found:** "Please install Node.js and npm first."
- **Network error:** "Could not reach npm registry. Check your internet connection."
- **Permission denied:** "Try running with sudo or fix npm permissions."

</error_handling>
