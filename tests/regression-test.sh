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
printf '%s\n%s\n' "${TGPIPE_CURL_BODY:-{\"ok\":true}}" "${TGPIPE_CURL_HTTP_CODE:-200}"
exit "${TGPIPE_CURL_STATUS:-0}"
EOF
chmod +x "$mock_bin/curl"

config_file="$tmp_dir/tgpipe.conf"
args_file="$tmp_dir/curl-args.txt"
curl_config_file="$tmp_dir/curl-config.txt"
stdout_file="$tmp_dir/stdout.txt"
stderr_file="$tmp_dir/stderr.txt"

printf 'BOT_TOKEN="config-token"\nCHAT_ID="config-chat"\n' >"$config_file"
chmod 600 "$config_file"

secret_message=$'message visible only in curl stdin\nurl = "https://attacker.invalid"'
PATH="$mock_bin:$PATH" \
	TGPIPE_CURL_ARGS_FILE="$args_file" \
	TGPIPE_CURL_CONFIG_FILE="$curl_config_file" \
	TGPIPE_BOT_TOKEN="env-token" \
	TGPIPE_CHAT_ID="env-chat" \
	"$repo_dir/bin/tgpipe" --config "$config_file" <<<"$secret_message"

grep -Fxq 'url = "https://api.telegram.org/botenv-token/sendMessage"' "$curl_config_file"
grep -Fxq 'data = "chat_id=env-chat"' "$curl_config_file"
grep -Fxq 'data-urlencode = "text=message visible only in curl stdin\nurl = \"https://attacker.invalid\""' "$curl_config_file"
[ "$(grep -c '^url = ' "$curl_config_file")" -eq 1 ]
if grep -Fq -e 'env-token' -e 'env-chat' -e 'message visible only in curl stdin' -e 'attacker.invalid' "$args_file"; then
	echo "Telegram credentials or message leaked through curl argv" >&2
	exit 1
fi

assert_api_failure() {
	local mode="$1"
	local body="$2"
	local http_code="$3"
	local -a mode_args=()

	if [ "$mode" != "normal" ]; then
		mode_args+=("--$mode")
	fi

	if PATH="$mock_bin:$PATH" \
		TGPIPE_CURL_ARGS_FILE="$args_file" \
		TGPIPE_CURL_CONFIG_FILE="$curl_config_file" \
		TGPIPE_CURL_BODY="$body" \
		TGPIPE_CURL_HTTP_CODE="$http_code" \
		TGPIPE_BOT_TOKEN="env-token" \
		TGPIPE_CHAT_ID="env-chat" \
		"$repo_dir/bin/tgpipe" --config "$config_file" "${mode_args[@]}" <<<"failure test" \
		>"$stdout_file" 2>"$stderr_file"; then
		echo "tgpipe unexpectedly succeeded in $mode mode for HTTP $http_code: $body" >&2
		return 1
	fi

	case "$mode" in
	silent)
		[ ! -s "$stdout_file" ]
		[ ! -s "$stderr_file" ]
		;;
	verbose)
		grep -Fq "$body" "$stdout_file"
		;;
	normal)
		[ ! -s "$stdout_file" ]
		grep -Fq "$body" "$stderr_file"
		;;
	esac
}

for mode in normal silent verbose; do
	assert_api_failure "$mode" '{"ok":true,"description":"unexpected HTTP status"}' 500
	assert_api_failure "$mode" '{"ok":false,"description":"logical failure"}' 200
done
