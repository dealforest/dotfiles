---
description: Analyze local changes and create meaningful separate commits
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git restore:*)
---

## Context

- Git status: !`git status`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`

## Rules

Follow these rules from the project:
1. Use Conventional Commits format: `type(scope): description`
2. One type per commit - separate fix, feat, docs, etc.
3. Keep commits small and focused on one logical change
4. Do not use generic tool names like 'claude' as scope

## Your task

Analyze all local changes and create meaningful separate commits:

1. **Analyze changes**: Group related changes by:
   - File type/location (same directory or feature)
   - Change type (feat, fix, docs, style, refactor, etc.)
   - Logical relationship (files that should be committed together)

2. **Plan commits**: For each logical group:
   - Determine the appropriate Conventional Commits type
   - Choose a specific scope (not generic names)
   - Write a concise description

3. **Execute commits**: For each planned commit:
   - Stage only the relevant files
   - Create the commit with proper message format
   - Verify with git status

4. **Report**: Show summary of created commits

Do not ask for confirmation - proceed with the analysis and commits.
