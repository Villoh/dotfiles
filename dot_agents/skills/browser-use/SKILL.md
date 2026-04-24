---
name: browser-use
description: Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, or extract information from web pages.
allowed-tools: Bash(browser-use:*)
---

# Browser Automation with browser-use CLI

Use `browser-use` when a task requires real browser interaction.

## Core workflow

1. Open the page with `browser-use open <url>`.
2. Inspect interactive elements with `browser-use state`.
3. Interact using the returned indices.
4. Verify with `browser-use state` or `browser-use screenshot`.

## Common commands

```bash
browser-use doctor
browser-use open <url>
browser-use state
browser-use click <index>
browser-use input <index> "text"
browser-use screenshot
browser-use close
```

## Notes

- Run `browser-use state` before clicking when you need fresh indices.
- If a session gets stuck, run `browser-use close` and retry.
- To reuse the user's browser session, use `browser-use connect`.
- For visible debugging, use `browser-use --headed open <url>`.
