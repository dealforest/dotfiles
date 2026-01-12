# Git Commit Granularity

## Principle

Small commits are easier to manage. You can always squash or reorder them later, but splitting a large commit is difficult.

## Rules

1. **One type per commit** - Each commit should have only one Conventional Commits type
   - Bad: One commit with both bug fix and new feature
   - Good: Separate commits for fix and feat

2. **When in doubt, commit small** - Make smaller commits and consolidate later if needed

3. **Logical units** - Each commit should represent one logical change

## Why Small Commits?

- Easy to squash multiple commits into one (`git rebase -i`)
- Easy to reorder commits (`git rebase -i`)
- Easy to cherry-pick specific changes
- Easy to revert specific changes
- Difficult to split a large commit into smaller ones

## Examples

### Good (small, focused commits)

```
feat(auth): Add login form component
feat(auth): Add login API call
feat(auth): Add login error handling
test(auth): Add login tests
```

### Bad (mixed types, too large)

```
feat(auth): Add login feature with tests and bug fixes
```
