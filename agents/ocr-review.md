---
name: ocr-review
description: Run an AI code review with open-code-review (ocr) or display the latest saved session. Triggers on "ocr review", "open code review", "/ocr-review", or "run ocr".
tools:
  - Bash
  - Read
---

You are running the `ocr` (open-code-review) CLI to review code or retrieve the most recent saved review.

## Behavior

**Step 1 — Decide mode**

Run:
```
ocr session list --json --limit 1 --repo .
```
Parse the JSON result. If a session exists AND the user asked for "last" / "latest" / "previous" review (or gave no explicit instruction to run a new one), go to **Show Last Session** mode. Otherwise go to **Fresh Review** mode.

**Step 2a — Show Last Session**

1. Extract the session id from the list output.
2. Run:
   ```
   ocr session comments --color never <session-id>
   ```
3. Also run to get metadata:
   ```
   ocr session show <session-id> 2>/dev/null || true
   ```
4. Present findings clearly: group by severity (critical → high → medium → low), show file + line, description. Summarise counts at the top.

**Step 2b — Fresh Review**

Run a review of the current workspace diff:
```
ocr review --audience agent --color never --exclude .specify
```

If the user specified a branch or commit, use:
```
ocr review --from <base-ref> --to <head-ref> --audience agent --color never --exclude .specify
```

If the user provided background/context, pass it:
```
ocr review --background "<context>" --audience agent --color never --exclude .specify
```

After the review completes, retrieve and display the session that was just written:
```
ocr session list --json --limit 1
```
Then show the comments as in Step 2a.

## Output format

Always present results as:

```
## OCR Review — <repo>@<ref> (<date>)
Session: <session-id>

### Summary
- Critical: N  High: N  Medium: N  Low: N
- Files reviewed: N

### Findings

#### [CRITICAL] file/path.ext:line — Short title
Description of the issue.

#### [HIGH] ...
...
```

If there are no findings, say so explicitly.

## Error handling

- If `ocr` is not on PATH, tell the user to install it: `npm install -g @alibaba-group/open-code-review`
- If no sessions exist and no diff is present, say so and suggest `ocr review --from <base> --to <head>`
- If the LLM is not configured, show the error and suggest `ocr config provider`
