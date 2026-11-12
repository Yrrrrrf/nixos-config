# Next Session Roadmap: `admin.yrrrrrf.dev`, Resource Optimization & On-Demand Services

**Date Target**: 12 November 2026  
**Primary Host**: `rpi5` (`192.168.100.167`, 8 GB RAM, 1 TB NVMe)  
**Related Docs**:
- [ROUTES.md](./ROUTES.md) — Current network routes & SSH commands
- [PI5-SERVER-ARCHITECTURE-AND-ROADMAP.md](./PI5-SERVER-ARCHITECTURE-AND-ROADMAP.md) — Hybrid architecture foundation

---

## 1. The Challenge Discovered in Today's Session

During runtime verification on 11 November 2026, `btop` revealed that **idle memory consumption on `rpi5` is ~3.23 GiB (41%)**:

| Process / Service | Idle RAM Footprint | Runtime Nature |
| :--- | :--- | :--- |
| **`open-webui`** (`python3`) | **~906 MiB** (~12%) | Heavy (FastAPI, PyTorch & embeddings libraries loaded in RAM) |
| **`n8n`** (`node` V8 engine) | **~833 MiB** (~11%) | Heavy (V8 heap & workflow execution runtime) |
| **`gitea`** (compiled Go) | **~152 MiB** (~2%) | Very Lean (compiled native binary) |
| **`cloudflared`** (compiled Go) | **~39 MiB** (~0.5%) | Tiny (tunnel multiplexer) |

### The Problem
* **Open-WebUI and n8n consume ~1.75 GiB of RAM continuously**, even when no one is using them.
* If both are stopped when not needed, the Pi drops to **~1.2 GiB idle RAM** (leaving **85%+ of RAM completely free** for compilation, cache, and other services).
* However, stopping them currently causes Cloudflare to return an unstyled, generic **502 Bad Gateway** error.

---

## 2. Phase 1 Goal: `admin.yrrrrrf.dev` via Cockpit

Deploy **Cockpit** as the system management and service toggle console.

### Why Cockpit?
1. **Extremely Lightweight**: Written in C; draws only ~20–30 MB RAM while someone is viewing it, and essentially 0 MB when idle.
2. **First-Class NixOS Module**: Declarative activation via `services.cockpit.enable = true;`.
3. **Mobile-Friendly System Control**:
   - Live CPU, RAM, disk I/O, and temperature graphs.
   - **System Services Tab**: Tap a single toggle button to `Start` or `Stop` `open-webui` or `n8n` on demand from a phone or laptop.
   - Integrated web-based emergency terminal.

### Phase 1 Execution Plan
1. Add Cockpit to `src/system/frontier-hosting.nix` on `rpi5`:
   ```nix
   services.cockpit = {
     enable = true;
     port = 9090;
     settings = {
       WebService = {
         Origins = "https://admin.yrrrrrf.dev";
         ProtocolHeader = "X-Forwarded-Proto";
       };
     };
   };
   ```
2. Route `admin.yrrrrrf.dev` in Cloudflare Tunnel (`services.cloudflared.tunnels.<UUID>.ingress`):
   ```nix
   "admin.yrrrrrf.dev" = "http://127.0.0.1:9090";
   ```
3. Route DNS in Cloudflare:
   ```bash
   cloudflared tunnel route dns rpi5 admin.yrrrrrf.dev
   ```
4. Protect `admin.yrrrrrf.dev` with Cloudflare Access application using the existing `only-me` policy (`fer.rezac@outlook.com`).

---

## 3. Phase 2 Goal: Custom Fallback Pages (Handling Stopped Services)

When a service (like Open-WebUI or n8n) is stopped to save RAM, visitors should see an informative status page instead of a raw 502 error.

### Strategy: Local Reverse Proxy Catch-All (Caddy / Nginx)
* Point the Cloudflare tunnel for `open-webui` and `n8n` to local proxy ports.
* If the target daemon (`:7777` or `:5678`) is not responding, serve a lightweight, styled dark-mode HTML page:
  > **"Service is Sleeping"**  
  > *"Open-WebUI is currently spun down to conserve memory on the Raspberry Pi 5. Head over to [admin.yrrrrrf.dev](https://admin.yrrrrrf.dev) to start it."*

---

## 4. Phase 3 Goal (Optional / Advanced): Automatic Wake-on-Request (Sablier)

Automate the sleep/wake lifecycle completely:
1. **Auto-Sleep**: If no HTTP requests hit `open-webui.yrrrrrf.dev` for 30 minutes, automatically run `systemctl stop open-webui`.
2. **Wake-on-Request**: When someone navigates to `https://open-webui.yrrrrrf.dev`, an intermediary proxy (like **Sablier**):
   - Catches the request.
   - Displays a sleek loading screen (*"Waking up AI engine..."*).
   - Starts the systemd unit `open-webui.service`.
   - Forwards the user into Open-WebUI as soon as the port answers.

---

## 5. Quick Checklist for Tomorrow's Session

- [ ] Add `services.cockpit` configuration to `frontier-hosting.nix` on `rpi5`.
- [ ] Add `admin.yrrrrrf.dev` ingress rule and DNS CNAME.
- [ ] Add Cloudflare Access application for `admin.yrrrrrf.dev` (`only-me` policy).
- [ ] Rebuild `rpi5` and verify login at `https://admin.yrrrrrf.dev`.
- [ ] Test toggling `open-webui` and `n8n` off from Cockpit and watch RAM drop in `btop`.
- [ ] (Optional) Implement fallback page or Sablier on-demand wake proxy.
