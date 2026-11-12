# `yrrrrrf.dev` & Infrastructure Network Routes

Quick reference index of all active public subdomains, Cloudflare Zero Trust Access policies, internal backend ports, and LAN connection endpoints.

---

## 1. Public Subdomains (`*.yrrrrrf.dev`)

All routed through Cloudflare Named Tunnel **`rpi5`** (`9d4882e5-7305-49f1-a186-5f4ecc31b99a`) to the Raspberry Pi 5 (`192.168.100.167`).

| Hostname | Target on `rpi5` | Service | Protection / Policy | Status |
| :--- | :--- | :--- | :--- | :--- |
| **`https://open-webui.yrrrrrf.dev`** | `http://127.0.0.1:7777` | **Open-WebUI** (LLM Chat) | Cloudflare Access (`only-me`) | 🟢 **Active** (uses `g14` Ollama over LAN) |
| **`https://n8n.yrrrrrf.dev`** | `http://127.0.0.1:5678` | **n8n** (Automations & Flows) | Cloudflare Access (`only-me`) | 🟢 **Active** |
| **`https://git.yrrrrrf.dev`** | `http://127.0.0.1:3001` | **Gitea** (Private Git Server) | Cloudflare Access (`only-me`) | 🟢 **Active** (admin: `yrrrrrf`) |
| **`ssh.yrrrrrf.dev`** | `ssh://127.0.0.1:22` | **Pi 5 SSH Daemon** | Cloudflare Access (`only-me`) + Ed25519 Key | 🟢 **Active** |
| **`https://yrrrrrf.dev`** | `http://127.0.0.1:8080` | Root Landing Page / Portfolio | Public (when deployed) | ⏳ Routed (502 until service bound) |
| **`https://page.yrrrrrf.dev`** | `http://127.0.0.1:8080` | Docs / Static Pages | Public (when deployed) | ⏳ Routed (502 until service bound) |
| **`https://api.yrrrrrf.dev`** | `http://127.0.0.1:3000` | Custom API / Microservices | Public (app token auth) | ⏳ Routed (502 until service bound) |

> [!NOTE]
> **Authentication email for Cloudflare Access**: `fer.rezac@outlook.com` (OTP pin sent on login).

---

## 2. SSH Access Commands

Always run these from your daily laptop (**`g14`**) where `~/.ssh/id_ed25519` resides.

### Home LAN (Direct, Fastest)
```bash
ssh -i ~/.ssh/id_ed25519 yrrrrrf@192.168.100.167
```

### Remote (Anywhere in the World via Cloudflare Tunnel)
```bash
ssh -i ~/.ssh/id_ed25519 -o ProxyCommand="cloudflared access ssh --hostname ssh.yrrrrrf.dev" yrrrrrf@ssh.yrrrrrf.dev
```

---

## 3. LAN Endpoints & Host Summary

| Host | LAN IP | Role | Notable Ports & Endpoints |
| :--- | :--- | :--- | :--- |
| **`rpi5`** | `192.168.100.167` | 24/7 Always-On Server | `:22` (SSH), `:3001` (Gitea), `:5678` (n8n), `:7777` (Open-WebUI) |
| **`g14`** | `192.168.100.197` | Daily Workstation & CUDA Node | `:11434` (Ollama CUDA `sm_89`, firewalled to accept LAN requests from `192.168.100.167`) |

---

## 4. Configuration File Locations

- **G14 Config**: `/etc/nixos/src/system/llms.nix` & `/etc/nixos/src/host/g14/g14.nix`
- **Pi 5 Config**: `/etc/nixos/src/system/frontier-hosting.nix` & `/etc/nixos/src/host/rpi5/rpi5.nix`
- **Cloudflare Credentials (Pi 5)**: `/var/lib/cloudflared/rpi5.json` (`0600`, root-owned)
- **Architecture Roadmap**: `/etc/nixos/PI5-SERVER-ARCHITECTURE-AND-ROADMAP.md`
