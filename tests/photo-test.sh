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
cat >"${TGPIPE_CURL_CONFIG_FILE:?}"
printf '{"ok":true}\n200\n'
EOF
chmod +x "$mock_bin/curl"

photo_file="$tmp_dir/photo.jpg"
args_file="$tmp_dir/curl-args.txt"
config_input_file="$tmp_dir/curl-config-input.txt"
printf 'fake image bytes\n' >"$photo_file"

PATH="$mock_bin:$PATH" \
	TGPIPE_CURL_ARGS_FILE="$args_file" \
	TGPIPE_CURL_CONFIG_FILE="$config_input_file" \
	TGPIPE_BOT_TOKEN="test-token" \
	TGPIPE_CHAT_ID="12345" \
	"$repo_dir/bin/tgpipe" --photo "$photo_file" <<<"photo caption"

grep -Fxq 'url = "https://api.telegram.org/bottest-token/sendPhoto"' "$config_input_file"
grep -Fxq "form = \"photo=@$photo_file\"" "$config_input_file"
grep -Fxq 'form = "caption=photo caption"' "$config_input_file"
if grep -Fq -e "test-token" -e "photo caption" "$args_file"; then
	echo "bot token or photo caption leaked through curl argv" >&2
	exit 1
fi
