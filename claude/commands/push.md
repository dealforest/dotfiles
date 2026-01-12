---
description: Push committed changes to remote
allowed-tools: Bash(git push:*), Bash(git status:*), Bash(git log:*)
---

## Context

- Current branch: !`git branch --show-current`
- Commits ahead of remote: !`git log --oneline @{u}..HEAD 2>/dev/null || echo "No upstream branch"`
- Git status: !`git status --short`

## Your task

Push committed changes to the remote repository.

1. Check if there are commits to push
2. If there are unpushed commits, push to remote
3. Report the result

Do not commit any changes. Only push existing commits.
