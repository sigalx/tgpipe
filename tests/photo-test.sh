#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"

cleanup() {
	rm -rf "$tmp_dir"
}
trap cleanup EXIT

mock_bin="$tmp_dir/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/curl" <<'EOF'
#!/bin/bash
set -euo pipefail

printf '%s\n' "$@" >"${TGPIPE_CURL_ARGS_FILE:?}"
printf '{"ok":true}\n200\n'
EOF
chmod +x "$mock_bin/curl"

photo_file="$tmp_dir/photo.jpg"
args_file="$tmp_dir/curl-args.txt"
printf 'fake image bytes\n' >"$photo_file"

PATH="$mock_bin:$PATH" \
	TGPIPE_CURL_ARGS_FILE="$args_file" \
	TGPIPE_BOT_TOKEN="test-token" \
	TGPIPE_CHAT_ID="12345" \
	"$repo_dir/bin/tgpipe" --photo "$photo_file" <<<"photo caption"

grep -Fxq "https://api.telegram.org/bottest-token/sendPhoto" "$args_file"
grep -Fxq "photo=@$photo_file" "$args_file"
grep -Fxq "caption=photo caption" "$args_file"
