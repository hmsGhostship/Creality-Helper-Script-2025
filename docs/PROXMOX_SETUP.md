# Proxmox LXC Setup Guide (Spoolman & K1C CFS-C Mobile App)

Running **Spoolman** and the **K1C CFS-C Mobile App** inside a lightweight **Proxmox LXC container** keeps both services available 24/7 on your local network without needing a Windows/Mac PC running—and gives the Expo Go mobile app a direct bridged LAN IP so no cloud tunnel or Expo account is required.

---

## 1. Create a Proxmox LXC Container

1. In the Proxmox Web UI, click **Create CT**:
   * **Template:** Debian 12 or Ubuntu 24.04
   * **Disk:** `8 GB`
   * **CPU:** `1` core
   * **Memory:** `1024 MB` RAM (`512 MB` Swap)
   * **Network:** Bridge `vmbr0` with **DHCP** (or a static IP in your home LAN, e.g. `192.168.178.95/24`)
2. Start the container, open its **Console**, and update packages:
   ```bash
   apt update && apt upgrade -y
   apt install -y curl git ca-certificates gnupg
   ```

---

## 2. Install Spoolman (Port `7912`)

1. **Install Docker & Docker Compose:**
   ```bash
   curl -fsSL https://docker.com | sh
   ```
2. **Create the Spoolman directory and `docker-compose.yml`:**
   ```bash
   mkdir -p /opt/spoolman/data
   chown -R 1000:1000 /opt/spoolman/data

   cat << 'YAML' > /opt/spoolman/docker-compose.yml
   services:
     spoolman:
       image: ghcr.io/donkie/spoolman:latest
       restart: unless-stopped
       volumes:
         - /opt/spoolman/data:/home/app/.local/share/spoolman
       ports:
         - "7912:8000"
       environment:
         - TZ=Europe/Berlin
   YAML
   ```
3. **Start Spoolman:**
   ```bash
   cd /opt/spoolman
   docker compose up -d
   ```
4. Verify in your browser at `http://<LXC-IP>:7912`, then enter `<LXC-IP>` and port `7912` in the K1C Material Database Editor (**Settings -> Spoolman External Database**).

---

## 3. Install & Autostart the K1C CFS-C Mobile App (`app/`)

1. **Install Node.js (v20 LTS):**
   ```bash
   curl -fsSL https://nodesource.com | bash -
   apt install -y nodejs
   ```
2. **Clone the repository and install dependencies:**
   ```bash
   git clone https://github.com /opt/creality-cfs-app
   cd /opt/creality-cfs-app/app
   npm install
   ```
3. **Create a `systemd` service for automatic 24/7 startup:**
   ```bash
   cat << 'SERVICE' > /etc/systemd/system/k1c-cfs-app.service
   [Unit]
   Description=K1C CFS-C Mobile App Expo Server
   After=network-online.target
   Wants=network-online.target

   [Service]
   Type=simple
   WorkingDirectory=/opt/creality-cfs-app/app
   Environment=CI=1
   ExecStart=/usr/bin/npx expo start --lan --port 8081
   Restart=always
   RestartSec=5

   [Install]
   WantedBy=multi-user.target
   SERVICE

   systemctl daemon-reload
   systemctl enable --now k1c-cfs-app.service
   ```
4. **Connect from iOS / Android (Expo Go):**
   * Open **Expo Go** on your phone (connected to the same Wi-Fi network).
   * Tap **Enter URL manually** and enter:
     ```text
     exp://<LXC-IP>:8081
     ```
   * *(Tip: To update the app later, run `git -C /opt/creality-cfs-app pull && systemctl restart k1c-cfs-app.service`.)*
