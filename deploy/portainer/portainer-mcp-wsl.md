# Portainer MCP on WSL (Ubuntu)

This guide documents how to install and run the official [Portainer MCP server](https://github.com/portainer/portainer-mcp) inside a WSL2 Ubuntu environment and optionally integrate it with an AI client (e.g. Claude Desktop).

> MCP (Model Context Protocol) standardizes how applications expose context & tools to LLMs. Portainer MCP lets an AI assistant query and (optionally) manage Portainer resources.

## Supported Portainer Versions

Each MCP release targets a specific Portainer version (validation occurs at startup). Current mapping (abridged):

| MCP | Portainer |
|-----|-----------|
| 0.5.0 | 2.30.0 |
| 0.6.0 | 2.31.2 |

If your Portainer version differs, you can append `-disable-version-check` (feature compatibility may be partial).

## Prerequisites

- WSL2 Ubuntu distro (Windows 11 recommended) with network access to your Portainer instance.
- Portainer instance URL & admin API token.
- `curl`, `tar`, `md5sum` (install via `sudo apt update && sudo apt install -y curl coreutils tar`).
- Optional: `tmux` (for background run without systemd) or systemd user instance enabled in WSL (recent Windows builds allow this via settings).

## 1) Set Variables

```bash
export MCP_VER="v0.6.0"          # latest release tag
export MCP_ARCH="linux-amd64"    # or linux-arm64 if on ARM
export PORTAINER_HOST="https://localhost:9443"  # adjust to your instance
export PORTAINER_TOKEN="ptok_xxxxxxxxx"          # replace with your API key
```

## 2) Download + Verify Binary

```bash
cd /tmp
curl -LO "https://github.com/portainer/portainer-mcp/releases/download/${MCP_VER}/portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz"
curl -LO "https://github.com/portainer/portainer-mcp/releases/download/${MCP_VER}/portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz.md5"
md5sum -c "portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz.md5"  # Expect OK
```

## 3) Install

```bash
tar -xzf "portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz"
sudo mv portainer-mcp /usr/local/bin/
sudo chmod 0755 /usr/local/bin/portainer-mcp
which portainer-mcp
```

## 4) First Run (Foreground)

```bash
portainer-mcp -server "${PORTAINER_HOST}" -token "${PORTAINER_TOKEN}"
```

If you hit a version mismatch:

```bash
portainer-mcp -server "${PORTAINER_HOST}" -token "${PORTAINER_TOKEN}" -disable-version-check
```

Read-only (no writes, no proxy tools):

```bash
portainer-mcp -server "${PORTAINER_HOST}" -token "${PORTAINER_TOKEN}" -read-only
```

## 5) Tools File (Optional)

By default the binary creates `tools.yaml` in its directory if absent. To customize definitions and keep them under your home directory:

```bash
mkdir -p ~/.config/portainer-mcp
# Example run that also generates/uses a custom tools file path
portainer-mcp -server "${PORTAINER_HOST}" -token "${PORTAINER_TOKEN}" -tools ~/.config/portainer-mcp/tools.yaml
```

Edit descriptions only—do not rename tools or change parameter schemas.

## 6) Background Operation

### A. systemd User Service (if systemd enabled in WSL)

Check systemd availability:

```bash
systemctl --user --version || echo "User systemd not available"
```

Create service:

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/portainer-mcp.service <<'EOF'
[Unit]
Description=Portainer MCP Server
After=network-online.target

[Service]
Type=simple
Environment=PORTAINER_HOST=https://localhost:9443
Environment=PORTAINER_TOKEN=ptok_xxxxxxxxx
ExecStart=/usr/local/bin/portainer-mcp -server ${PORTAINER_HOST} -token ${PORTAINER_TOKEN} -tools /home/%u/.config/portainer-mcp/tools.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now portainer-mcp.service
systemctl --user status portainer-mcp.service --no-pager
```

### B. tmux Session (portable fallback)

```bash
tmux new -d -s portainer-mcp 'portainer-mcp -server "${PORTAINER_HOST}" -token "${PORTAINER_TOKEN}"'
```

List / attach:

```bash
tmux ls
tmux attach -t portainer-mcp
```

### C. Simple nohup

```bash
mkdir -p ~/.config/portainer-mcp
nohup portainer-mcp -server "${PORTAINER_HOST}" -token "${PORTAINER_TOKEN}" > ~/.config/portainer-mcp/mcp.log 2>&1 &
```

## 7) Claude Desktop Integration Example

In Claude config (replace token & paths):

```json
{
  "mcpServers": {
    "portainer": {
      "command": "/usr/local/bin/portainer-mcp",
      "args": [
        "-server", "https://localhost:9443",
        "-token", "ptok_xxxxxxxxx",
        "-tools", "/home/youruser/.config/portainer-mcp/tools.yaml"
      ]
    }
  }
}
```

Add `"-read-only"` or `"-disable-version-check"` to args as needed.

## 8) Updating

```bash
# If using systemd user service
systemctl --user stop portainer-mcp.service || true

export MCP_VER="v0.6.1"  # new tag
cd /tmp
curl -LO "https://github.com/portainer/portainer-mcp/releases/download/${MCP_VER}/portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz"
curl -LO "https://github.com/portainer/portainer-mcp/releases/download/${MCP_VER}/portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz.md5"
md5sum -c "portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz.md5"
tar -xzf "portainer-mcp-${MCP_VER}-${MCP_ARCH}.tar.gz"
sudo mv portainer-mcp /usr/local/bin/

systemctl --user restart portainer-mcp.service || true
```

## 9) Security Suggestions

- Prefer a dedicated Portainer admin API key you can revoke independently.
- Use `-read-only` mode for exploratory or audit sessions.
- Avoid embedding tokens in version-controlled files; load via env exports.
- Rotate tokens periodically.

## 10) Troubleshooting

| Issue | Cause | Resolution |
|-------|-------|------------|
| Version mismatch fail | Portainer version unsupported | Use `-disable-version-check`; verify features individually |
| Connection refused | Wrong host/port or firewall | Confirm `curl -k $PORTAINER_HOST/api/system/status` works |
| Tools file not created | Path unwritable | Choose a user-writable path like `~/.config/portainer-mcp` |
| Partial tool failures | API differences | Upgrade Portainer or MCP to matched versions |
| Self-signed TLS errors | Certificate trust issues | Use `https` with imported CA or (last resort) run Portainer on `http` internally |

## 11) Uninstall

```bash
systemctl --user disable --now portainer-mcp.service 2>/dev/null || true
rm -f /usr/local/bin/portainer-mcp
rm -rf ~/.config/portainer-mcp
```

---

**Note:** This guide is derived from the official project README with WSL-specific adjustments. Keep an eye on upstream release notes for flags or compatibility updates.
