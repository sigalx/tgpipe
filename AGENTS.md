# Repository Guidelines

## Project Structure & Modules
- `bin/tgpipe`: main Bash CLI (requires Bash ≥4.4; uses arrays and `[[ ... ]]`, so not POSIX-sh compatible); keep logic here modular with small helpers (e.g., `json_escape`, `html_escape`).
- `etc/tgpipe.conf.example`: reference config; never commit real tokens.
- `tests/`: smoke tests (`smoke-test.sh`) that exercise the CLI end-to-end.
- `assets/`, `man/`, `debian/`: branding, man page source, and Debian packaging metadata.
- `Makefile`: entry point for linting, testing, packaging, and release helpers.
- `.gitattributes`: enforces LF endings for text/shell/config files and marks build artifacts as binary.

## Build, Test, and Development Commands
- `make lint`: run `shellcheck` and `shfmt -d` on `bin/tgpipe`.
- `make fmt`: auto-format shell sources with `shfmt -w`.
- `TGPIPE_BOT_TOKEN=... TGPIPE_CHAT_ID=... make test`: run smoke test; requires real bot token and chat ID.
- `make man`: gzip the man page for packaging.
- `make deb` / `make dist` / `make release`: build Debian package, source tarball, and combined release artifacts; assumes Debian build deps are installed.
- Debian packaging: `dpkg-buildpackage` uses debhelper with `debian/install` to stage files (no auto-build). If you add build steps, add `override_dh_auto_install` that runs `make install DESTDIR=$(CURDIR)/debian/tgpipe` to keep paths consistent with the Makefile.

## Coding Style & Naming Conventions
- Shell scripts target Bash ≥4.4; keep `set -o nounset -o pipefail` and prefer explicit `if`/`case`.
- `shfmt` with defaults: tabs for indentation are intentional; do not switch to spaces. Keep `shellcheck` clean; add suppressions only with comments explaining why.
- Function and variable names are lower_snake_case; CLI flags are long/kebab (`--chat`, `--auto-code`); env vars are upper-snake with `TGPIPE_`; config keys in `/etc/tgpipe.conf` stay uppercase.
- Validate user input early (`--file` path, button payloads) and produce actionable error messages on `stderr`.

## Testing Guidelines
- Add new tests under `tests/` as `*-test.sh`; mirror the smoke test pattern and fail fast (`set -euo pipefail`).
- Use a dedicated test bot/token and test `CHAT_ID` that can receive automated noise; avoid production chats.
- When adding CLI flags, extend the smoke test to cover happy path and basic failure modes.

## Commit & Pull Request Guidelines
- Commits should be concise, present tense, and scoped to a single concern (e.g., `Add photo send helper`, `Harden button parsing`); keep subject lines under ~72 chars.
- For PRs, include: what changed, why, and how to validate (commands or sample invocations). Link related issues and include screenshots or sample outputs only when UI/formatting changes are relevant (e.g., man page snippets).
- Note any secrets/config requirements (e.g., `TGPIPE_*` env vars) in the PR description so reviewers can reproduce tests.

## Security & Configuration Tips
- Never commit real `BOT_TOKEN`/`CHAT_ID`; use `/etc/tgpipe.conf` or `TGPIPE_*` env vars locally and ensure permissions are `0600`.
- Prefer piping sensitive logs via `--auto-code` to avoid Telegram formatting surprises; disable previews for URLs when in doubt.
- Validate filenames before sending files/photos to avoid unexpected uploads from user input.

## Backward Compatibility
- Do not break stable CLI flags or defaults; when introducing changes, keep old flag names/behavior working or add shims with clear deprecation notes in the help text and changelog.
