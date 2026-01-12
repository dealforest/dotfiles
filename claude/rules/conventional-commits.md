# Conventional Commits

When creating git commits, follow the Conventional Commits specification.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | Description |
|------|-------------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation changes |
| style | Code style changes (formatting, no logic change) |
| refactor | Code refactoring (no feature/fix) |
| perf | Performance improvement |
| test | Adding or updating tests |
| build | Build system or dependencies |
| ci | CI/CD configuration |
| chore | Maintenance tasks |

## Scope

Scope is optional and describes the section of the codebase affected by the change.

```
feat(auth): Add OAuth2 login support
fix(ui): Resolve button alignment issue
refactor(api): Simplify error handling
```

Common scopes: `auth`, `ui`, `api`, `db`, `config`, `deps`, `core`

## Body

The body provides additional context. It must be separated from the description by a blank line.

- Use the body to explain **what** and **why**, not how
- Can contain multiple paragraphs
- Wrap lines at 72 characters

```
fix: Prevent race condition in user session

The session was being accessed before initialization completed.
This caused intermittent crashes on app startup.

Added a mutex lock to ensure thread-safe access.
```

## Breaking Changes

Breaking changes indicate incompatible API changes. There are two ways to indicate a breaking change:

### 1. Add `!` after type/scope

```
feat!: Remove deprecated API endpoints

feat(api)!: Change authentication flow
```

### 2. Add `BREAKING CHANGE:` in footer

```
feat: Refactor user authentication

BREAKING CHANGE: The login endpoint now requires email instead of username.
Old: POST /login { username, password }
New: POST /login { email, password }
```

Both methods can be combined. `BREAKING-CHANGE` (hyphenated) is also valid.

## Footers

Footers provide metadata and must be separated from the body by a blank line.

| Footer | Description |
|--------|-------------|
| `BREAKING CHANGE:` | Describes breaking changes |
| `Refs #123` | References related issues |
| `Fixes #456` | Closes an issue when merged |
| `Reviewed-by: Name` | Code reviewer |

```
feat(auth): Add two-factor authentication

Implements TOTP-based 2FA for enhanced security.

Fixes #234
Refs #123
```

## Semantic Versioning

Conventional Commits correlate with Semantic Versioning (SemVer):

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix` | PATCH (0.0.x) | 1.0.0 → 1.0.1 |
| `feat` | MINOR (0.x.0) | 1.0.0 → 1.1.0 |
| `BREAKING CHANGE` | MAJOR (x.0.0) | 1.0.0 → 2.0.0 |

## Revert

When reverting a previous commit, use `revert:` type with the original commit's subject.

```
revert: feat(auth): Add OAuth2 login support

This reverts commit abc1234.
Reason: OAuth provider deprecated their API.
```

## Rules

1. Type is required and must be lowercase
2. Description must be in imperative mood ("Add feature" not "Added feature")
3. Description should not end with a period
4. Keep the first line under 72 characters
5. Use body for detailed explanation if needed

## Examples

### Simple (description only)

```
feat: Add video generation feature
fix: Resolve crash on app startup
docs: Update README with installation steps
```

### With scope

```
feat(video): Add generation from two frames
fix(auth): Handle expired token gracefully
```

### With body and footer

```
fix(ui): Defer screen capture prevention on iOS

usePreventScreenCapture() was called before the native view hierarchy
was ready, causing EXC_BAD_ACCESS crash on startup.

- Move prevention to useEffect
- Add 500ms delay for iOS
- Add error handling

Fixes #789
```

### Breaking change

```
feat(api)!: Change authentication response format

BREAKING CHANGE: The /auth/login endpoint now returns
{ token, expiresAt } instead of { accessToken, refreshToken }.

Migration: Update client code to use the new token field.
```
