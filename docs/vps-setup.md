# VPS Setup Guide

Complete guide for provisioning a fresh Ubuntu 24.04 VPS and deploying the portfolio stack.

## Prerequisites

- A VPS running Ubuntu 24.04 with root SSH access
- A domain name pointing to the VPS IP (optional but recommended for HTTPS)

---

## 1. Initial Root Login

```bash
ssh root@YOUR_VPS_IP
```

Update the system first:

```bash
apt update && apt upgrade -y
apt install -y ufw curl git nano
```

---

## 2. Create a Non-Root User

Running everything as root is a security risk. Create a dedicated user instead.

```bash
# Create the user (replace 'deploy' with whatever you like)
adduser deploy

# Grant sudo privileges
usermod -aG sudo deploy
```

### Copy your SSH key to the new user

While still logged in as root, copy your authorized keys so you can SSH in as the new user:

```bash
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```

### Test the new user in a second terminal before closing root

Open a new terminal and verify you can log in:

```bash
ssh deploy@YOUR_VPS_IP
```

Once confirmed, you can optionally disable root SSH login:

```bash
# Back in your root session
nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
systemctl reload sshd
```

---

## 3. Configure the Firewall

Allow only SSH, HTTP, and HTTPS:

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
ufw status
```

> **Important:** UFW does **not** block ports bound by Docker. Docker writes iptables rules directly, bypassing UFW entirely. The production `compose.yaml` intentionally omits `ports:` from every internal service — only the nginx container binds host ports 80 and 443. Do not add port bindings back to internal services "for debugging"; use `docker compose exec` or an SSH tunnel instead:
>
> ```bash
> # Inspect the RabbitMQ management UI without exposing it to the internet
> ssh -L 15672:localhost:15672 deploy@YOUR_VPS_IP
> # Then open http://localhost:15672 in your browser
> ```

---

## 4. Install Docker

Log in as your non-root user (`deploy`) for all remaining steps.

```bash
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker apt repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow your user to run docker without sudo
sudo usermod -aG docker $USER
newgrp docker
```

Verify the installation:

```bash
docker compose version
docker run --rm hello-world
```

---

## 5. Clone the Repository

```bash
git clone https://github.com/hkarpinen/portfolio2.git ~/portfolio2
cd ~/portfolio2/infra
```

---

## 6. Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

Fill in the following — everything else has safe defaults for getting started:

| Variable | What to set |
|---|---|
| `POSTGRES_PASSWORD` | A strong random password (superuser — init only) |
| `IDENTITY_DB_PASSWORD` … `HOUSEHOLD_DB_PASSWORD` | One strong password per service (different from superuser) |
| `JWT_SECRET` | A random string, **at least 32 characters** |
| `RABBITMQ_USER` / `RABBITMQ_PASSWORD` | Change from defaults — do **not** use `guest/guest` |
| `IDENTITY_CONN` … `HOUSEHOLD_CONN` | Use the per-service users from `.env.example`, **not** the postgres superuser |
| `EMAIL_HOST` / `EMAIL_USERNAME` / `EMAIL_PASSWORD` | Real SMTP relay (Mailgun, Postmark, SES, etc.) |
| `OPENWEATHERMAP_API_KEY` | From [openweathermap.org/api](https://openweathermap.org/api) (free tier) |
| `PLAID_CLIENT_ID` / `PLAID_SECRET` | From [dashboard.plaid.com](https://dashboard.plaid.com) (optional) |
| `CORS_ORIGIN` | `https://hankkarpinen.com` |

To generate strong random values:

```bash
# JWT secret
openssl rand -base64 48

# DB passwords
openssl rand -hex 20
```

---

## 7. Pull Images and Start the Stack

```bash
docker compose pull
docker compose up -d
```

Check all services came up cleanly:

```bash
docker compose ps
```

All services should show `healthy` or `running`. If something is stuck, inspect its logs:

```bash
docker compose logs identity --tail=50
```

---

## 8. Verify the Deployment

```bash
# Frontend via nginx
curl http://localhost

# Backend health checks
curl http://localhost/api/identity/health
curl http://localhost/api/forum/health
curl http://localhost/api/finance/health
```

From your local machine:

```
http://YOUR_VPS_IP
```

---

## 9. HTTPS with Let's Encrypt

The nginx config is already set up for HTTPS — it just needs the certificates to exist before the stack starts.

### First-time certificate issuance

Obtain certs using certbot standalone **before** starting the full stack (port 80 must be free):

```bash
sudo apt install -y certbot
sudo certbot certonly --standalone -d hankkarpinen.com -d www.hankkarpinen.com
```

Certs land at `/etc/letsencrypt/live/hankkarpinen.com/`. The nginx container mounts `/etc/letsencrypt` read-only, so the paths are wired up automatically.

Then start the stack normally:

```bash
docker compose pull
docker compose up -d
```

### Certificate renewal

Certbot installs a systemd timer that auto-renews before expiry. Configure it to reload nginx after renewal:

```bash
# Create a deploy hook that signals nginx to reload its config
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh > /dev/null <<'EOF'
#!/bin/sh
cd /home/deploy/portfolio/infra
docker compose exec nginx nginx -s reload
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

Certbot renews via the HTTP-01 ACME challenge using the `/var/www/certbot` webroot volume, which nginx serves at `/.well-known/acme-challenge/` on port 80 — no downtime required.

Test renewal dry-run:

```bash
sudo certbot renew --dry-run
```

---

## 10. Useful Day-to-Day Commands

```bash
# View all service statuses
docker compose ps

# Follow logs for all services
docker compose logs -f

# Follow logs for a specific service
docker compose logs -f identity

# Pull latest images and redeploy
docker compose pull && docker compose up -d

# Stop the entire stack
docker compose down

# Stop the stack and wipe all data (destructive!)
docker compose down -v

# Restart a single service
docker compose restart forum

# Open a shell inside a running container
docker compose exec identity bash
```

---

## 11. GitHub Actions Auto-Deploy

The infra repo includes `.github/workflows/deploy.yml`, which SSHs into the VPS and runs `docker compose pull && docker compose up -d` on every push to `main`. You just need to configure four secrets in the repo's **Settings → Secrets and variables → Actions**.

### Required secrets

| Secret | Value |
|---|---|
| `DEPLOY_HOST` | VPS IP address or hostname |
| `DEPLOY_USER` | SSH username (e.g. `deploy`) |
| `DEPLOY_KEY` | Private SSH key (see below) |
| `DEPLOY_ENV` | Full contents of your `.env` file |

### Generate a deploy SSH key

Run this on your local machine — do **not** reuse your personal key:

```bash
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/github_deploy
```

Authorize the public key on the VPS:

```bash
ssh-copy-id -i ~/.ssh/github_deploy.pub deploy@YOUR_VPS_IP
```

Print the private key to copy into `DEPLOY_KEY`:

```bash
cat ~/.ssh/github_deploy
```

Paste the entire output, including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines.

### DEPLOY_ENV

Paste the full contents of your `infra/.env` file. The workflow writes it to `.env` on the VPS before running Docker Compose, so the VPS copy is always in sync with whatever is in the secret.
