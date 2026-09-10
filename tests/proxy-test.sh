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

config_file="$tmp_dir/tgpipe.conf"
args_file="$tmp_dir/curl-args.txt"
config_input_file="$tmp_dir/curl-config-input.txt"
proxy_url="socks5h://127.0.0.1:9050"
env_args_file="$tmp_dir/curl-env-args.txt"
env_config_input_file="$tmp_dir/curl-env-config-input.txt"
env_proxy_url="http://proxy.example:3128"
config_args_file="$tmp_dir/curl-config-args.txt"
config_config_input_file="$tmp_dir/curl-config-config-input.txt"
config_proxy_url="socks5://127.0.0.1:1080"

printf '# test config\n' >"$config_file"
chmod 600 "$config_file"

PATH="$mock_bin:$PATH" \
	TGPIPE_CURL_ARGS_FILE="$args_file" \
	TGPIPE_CURL_CONFIG_FILE="$config_input_file" \
	TGPIPE_BOT_TOKEN="test-token" \
	TGPIPE_CHAT_ID="12345" \
	"$repo_dir/bin/tgpipe" --config "$config_file" --proxy "$proxy_url" <<<"proxy test"

grep -Fxq 'proxy = "socks5h://127.0.0.1:9050"' "$config_input_file"
grep -Fxq 'url = "https://api.telegram.org/bottest-token/sendMessage"' "$config_input_file"
if grep -Fq -e "$proxy_url" -e "test-token" "$args_file"; then
	echo "proxy URL or bot token leaked through curl argv" >&2
	exit 1
fi

PATH="$mock_bin:$PATH" \
	TGPIPE_CURL_ARGS_FILE="$env_args_file" \
	TGPIPE_CURL_CONFIG_FILE="$env_config_input_file" \
	TGPIPE_BOT_TOKEN="test-token" \
	TGPIPE_CHAT_ID="12345" \
	TGPIPE_PROXY="$env_proxy_url" \
	"$repo_dir/bin/tgpipe" --config "$config_file" <<<"proxy env test"

grep -Fxq 'proxy = "http://proxy.example:3128"' "$env_config_input_file"
if grep -Fq "$env_proxy_url" "$env_args_file"; then
	echo "environment proxy URL leaked through curl argv" >&2
	exit 1
fi

printf 'PROXY="%s"\n' "$config_proxy_url" >"$config_file"

PATH="$mock_bin:$PATH" \
	TGPIPE_CURL_ARGS_FILE="$config_args_file" \
	TGPIPE_CURL_CONFIG_FILE="$config_config_input_file" \
	TGPIPE_BOT_TOKEN="test-token" \
	TGPIPE_CHAT_ID="12345" \
	TGPIPE_PROXY="" \
	"$repo_dir/bin/tgpipe" --config "$config_file" <<<"proxy config test"

grep -Fxq 'proxy = "socks5://127.0.0.1:1080"' "$config_config_input_file"
if grep -Fq "$config_proxy_url" "$config_args_file"; then
	echo "configured proxy URL leaked through curl argv" >&2
	exit 1
fi
