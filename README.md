# 🕊️ tgpipe  
### Pipe anything into Telegram.

`tgpipe` is a small but powerful CLI tool that sends text, logs, files and any other data to Telegram via the Bot API.  
Perfect for DevOps, monitoring, scripts, CI/CD and home automation.

Repository: https://github.com/sigalx/tgpipe

---

## Features

- Send text, files and photos
- Markdown and HTML support
- Multiple chats (`CHAT_ID="id1,id2"` or `--chat`)
- Silent notifications (`--disable-notification`)
- Disable link previews (`--disable-preview`)
- Inline buttons (`--button-url`, `--button`)
- Code mode (`--code`, `--auto-code`)
- Log tags (`--tag`)
- Smart splitting of long messages

---

## Installation

### 1. From source (generic Unix)

```bash
git clone https://github.com/sigalx/tgpipe.git
cd tgpipe

sudo install -m 0755 bin/tgpipe /usr/local/bin/tgpipe
sudo install -m 0644 etc/tgpipe.conf.example /etc/tgpipe.conf
sudo chmod 600 /etc/tgpipe.conf
```

Edit `/etc/tgpipe.conf`:

```bash
BOT_TOKEN="123456:ABCDEF..."
CHAT_ID="123456789"         # or multiple: "111,222,333"
```

### 2. Debian/Ubuntu: install from .deb

If you downloaded a release `.deb` (for example from GitHub Releases):

```bash
wget https://github.com/sigalx/tgpipe/releases/download/v1.0.0/tgpipe_1.0.0_all.deb
sudo dpkg -i tgpipe_1.0.0_all.deb
```

Then create config:

```bash
sudo cp /etc/tgpipe.conf.example /etc/tgpipe.conf
sudo chmod 600 /etc/tgpipe.conf
sudo nano /etc/tgpipe.conf
```

### 3. Optional: local APT repository for tgpipe

If you want to install/update tgpipe via `apt` on multiple machines:

```bash
sudo apt install dpkg-dev nginx
sudo mkdir -p /srv/apt/tgpipe
cd /srv/apt/tgpipe

# copy your .deb here
sudo cp /path/to/tgpipe_1.0.0_all.deb .

# build Packages index
sudo dpkg-scanpackages . /dev/null | gzip -9 > Packages.gz
```

Nginx snippet (e.g. `/etc/nginx/conf.d/tgpipe.repo.conf`):

```nginx
server {
    listen 8080;
    server_name _;

    location /tgpipe/ {
        root /srv/apt;
        autoindex on;
    }
}
```

Reload nginx:

```bash
sudo systemctl reload nginx
```

On client machines:

```bash
echo "deb [trusted=yes] http://your-server:8080/tgpipe ./" | sudo tee /etc/apt/sources.list.d/tgpipe.list
sudo apt update
sudo apt install tgpipe
```

This is a minimal, private APT repo suitable for small environments and lab setups.

---

## Quick start

```bash
tgpipe "Hello from tgpipe!"
tgpipe --html "<b>Bold</b> message"
echo "Log line" | tgpipe --tag myapp
```

---

## Examples

### Send a file

```bash
tgpipe --file /path/to/report.txt "New report"
```

### Multiple chats

```bash
tgpipe --chat 111111111 --chat 222222222,333333333 "Hello everyone"
```

### Inline buttons

```bash
tgpipe \
  --button-url "Open site=https://example.com" \
  --button "Confirm=confirm_action" \
  "Choose action"
```

### Logs with automatic code mode

```bash
journalctl -u nginx | tgpipe --tag nginx --auto-code
```

---

## Environment variables

- `TGPIPE_BOT_TOKEN` — overrides `BOT_TOKEN` from config
- `TGPIPE_CHAT_ID` — overrides `CHAT_ID` from config
- `TGPIPE_MAX_LEN` — maximum chunk size (default 4000)
- `TGPIPE_AUTO_CODE_THRESHOLD` — line length threshold for `--auto-code` (default 120)

---

## Packaging (Debian/Ubuntu)

The repository contains a `debian/` directory for building a native Debian package.

Build dependencies:

```bash
sudo apt install build-essential devscripts debhelper
```

Build the package:

```bash
dpkg-buildpackage -us -uc
```

Result:

```text
../tgpipe_1.0.0_all.deb
```

Install:

```bash
sudo dpkg -i ../tgpipe_1.0.0_all.deb
```

You can then optionally publish this `.deb` via a local APT repository (see above).

---

## Man page

After installing the man page manually:

```bash
sudo cp man/tgpipe.1 /usr/local/share/man/man1/
sudo mandb
man tgpipe
```

(If you install via `.deb`, the man page is installed automatically.)

---

## License

MIT. See [LICENSE](LICENSE).
