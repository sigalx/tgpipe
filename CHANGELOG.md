# Changelog

## v1.0.2

- Return a failure status for Telegram HTTP and API errors in every logging mode.
- Apply `TGPIPE_BOT_TOKEN` and `TGPIPE_CHAT_ID` overrides after loading config.
- Keep Telegram credentials and message contents out of `curl` process arguments.
- Add regression coverage for credential precedence, error handling and secure request input.

## v1.0.1

- Add proxy support via `--proxy`, `TGPIPE_PROXY` and `PROXY`.
- Fix `--photo` invocation so the selected file is passed to `sendPhoto`.
- Build Debian package artifacts on master pushes.

## v1.0.0

- Initial public release of tgpipe.
- Text, file and photo sending support.
- Markdown and HTML parse modes.
- Multiple chats via config or `--chat`.
- Silent notifications and link preview control.
- Inline buttons (`--button-url`, `--button`).
- Code mode (`--code`, `--auto-code`) with HTML escaping.
- Log tagging with `--tag`.
- Smart splitting of long messages by length and newlines.
- Configurable via `/etc/tgpipe.conf` and environment variables.
- Smoke test script and CI workflow with ShellCheck and shfmt.
- Man page `tgpipe(1)` and basic project structure.
