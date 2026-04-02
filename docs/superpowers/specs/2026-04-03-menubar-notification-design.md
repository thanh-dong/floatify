# Menubar Notification Popup - Design

## Overview

Improve the menubar mode notification popup to show more helpful runtime information.

## Content

- Robot emoji (configurable, default: 🤖)
- Project name (folder name, truncated with ellipsis if > 20 chars)
- Message text

## Layout

```
┌─────────────────────────────────────┐
│ 🤖  ProjectName              │  <- header row (28pt height)
│     Your message here...      │  <- message row (40pt height)
└─────────────────────────────────────┘
```

Panel size: 280x68 (unchanged)
Padding: 16 horizontal, 12 vertical (unchanged)
Corner radius: 14 (unchanged)

## Technical Changes

### CLI (`cli/main.swift`)
- Add `--project` flag (string)
- Include `project` field in JSON payload

### AppDelegate (`AppDelegate.swift`)
- Parse `project` from JSON payload
- Pass to FloatNotificationManager

### FloatNotificationManager (`FloatNotificationManager.swift`)
- Update `show(message:corner:duration:)` to accept project parameter
- Pass project to FloatNotificationView

### FloatNotificationView (`FloatNotificationView.swift`)
- Add `project: String?` property
- Update layout to show emoji + project name on first line
- Update message to second line

## IPC Protocol Update

```json
{
  "message": "Task complete!",
  "corner": "menubar",
  "duration": "6",
  "project": "my-project-name"
}
```

## Default Behavior

- If `--project` not provided, display "Claude Code" as fallback header text
- If project name > 20 chars, truncate with "..."
