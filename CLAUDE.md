# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**DuckNotify** — A macOS menu bar daemon that renders animated duck notifications in screen dead zones (bottom-left/bottom-right corners), triggered by Claude Code hooks.

Two components:
- **DuckNotify.app** — Background GUI app (LSUIElement, no Dock icon) owning a floating NSPanel overlay
- **duck-notify CLI** — Sends messages to the app via CFMessagePort IPC

## Build Commands

```bash
# Generate Xcode project
cd DuckNotify && xcodegen generate

# Build the app
xcodebuild -project DuckNotify.xcodeproj -scheme DuckNotify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

# Build just the CLI
xcodebuild -project DuckNotify.xcodeproj -scheme duck-notify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

## Architecture

```
Claude Code hooks → duck-notify CLI → CFMessagePort IPC → DuckNotify.app → NSPanel overlay
```

**Key technical decisions:**
- CFMessagePort for sub-ms IPC (no network permissions needed)
- NSPanel with `.nonactivatingPanel` to avoid stealing keyboard focus
- `NSScreen.visibleFrame` for automatic Dock/Menubar exclusion
- `.popUpMenu` level floats above all apps including fullscreen windows
- Max 3 stacked panels with 4px vertical offset

## Project Structure

```
DuckNotify/
├── project.yml              # XcodeGen config
├── DuckNotify/              # macOS App target
│   ├── AppDelegate.swift    # CFMessagePort server + menu bar + symlink install
│   ├── DuckNotificationManager.swift  # NSPanel factory + stacking
│   ├── DuckNotificationView.swift    # SwiftUI notification view
│   ├── Corner.swift         # Corner enum
│   └── Info.plist           # LSUIElement = true
└── duck-notify/             # Command Line Tool target
    └── main.swift           # Argument parser + CFMessagePort client
```

## IPC Protocol

**Port name:** `com.yourname.duck-notify`

**JSON payload:**
```json
{
  "message": "Task complete!",
  "corner": "bottomRight",
  "duration": "6"
}
```

## Configuration for Claude Code

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "duck-notify --message '🦆 Claude is waiting for your next prompt' --corner bottomRight --duration 10"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "duck-notify --message 'Bash task done ✓' --corner bottomLeft --duration 5"
      }]
    }]
  }
}
```

## Output
- Answer is always line 1. Reasoning comes after, never before.
- No preamble. No "Great question!", "Sure!", "Of course!", "Certainly!", "Absolutely!".
- No hollow closings. No "I hope this helps!", "Let me know if you need anything!".
- No restating the prompt. If the task is clear, execute immediately.
- No explaining what you are about to do. Just do it.
- No unsolicited suggestions. Do exactly what was asked, nothing more.
- Structured output only: bullets, tables, code blocks. Prose only when explicitly requested.

## Token Efficiency
- Compress responses. Every sentence must earn its place.
- No redundant context. Do not repeat information already established in the session.
- No long intros or transitions between sections.
- Short responses are correct unless depth is explicitly requested.

## Typography - ASCII Only
- No em dashes (-) - use hyphens (-)
- No smart/curly quotes (" " ' ') - use straight quotes (" ')
- No ellipsis character (...) - use three dots (...)
- No Unicode bullets - use hyphens (-) or asterisks (*)
- No non-breaking spaces

## Sycophancy - Zero Tolerance
- Never validate the user before answering.
- Never say "You're absolutely right!" unless the user made a verifiable correct statement.
- Disagree when wrong. State the correction directly.
- Do not change a correct answer because the user pushes back.

## Accuracy and Speculation Control
- Never speculate about code, files, or APIs you have not read.
- If referencing a file or function: read it first, then answer.
- If unsure: say "I don't know." Never guess confidently.
- Never invent file paths, function names, or API signatures.
- If a user corrects a factual claim: accept it as ground truth for the entire session. Never re-assert the original claim.

## Code Output
- Return the simplest working solution. No over-engineering.
- No abstractions or helpers for single-use operations.
- No speculative features or future-proofing.
- No docstrings or comments on code that was not changed.
- Inline comments only where logic is non-obvious.
- Read the file before modifying it. Never edit blind.

## Warnings and Disclaimers
- No safety disclaimers unless there is a genuine life-safety or legal risk.
- No "Note that...", "Keep in mind that...", "It's worth mentioning..." soft warnings.
- No "As an AI, I..." framing.

## Session Memory
- Learn user corrections and preferences within the session.
- Apply them silently. Do not re-announce learned behavior.
- If the user corrects a mistake: fix it, remember it, move on.

## Scope Control
- Do not add features beyond what was asked.
- Do not refactor surrounding code when fixing a bug.
- Do not create new files unless strictly necessary.

## Override Rule
User instructions always override this file.
