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

> **Important:** UFW does **not** block ports bound by Docker. Docker writes iptables rules directly, bypassing UFW entirely. The production `compose.yaml` intentionally omits `ports:` from every internal service — only the gateway container binds host ports 80 and 443. Do not add port bindings back to internal services "for debugging"; use `docker compose exec` or an SSH tunnel instead:
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

## 5. Configure GitHub Actions Auto-Deploy

Run appleboy/ssh-action@v1.0.3
/usr/bin/docker run --name b1c2d0f3e093feec4adb91abbca76f725622_999dfb --label 33b1c2 --workdir /github/workspace --rm -e "INPUT_HOST" -e "INPUT_USERNAME" -e "INPUT_KEY" -e "INPUT_SCRIPT" -e "INPUT_PORT" -e "INPUT_PASSPHRASE" -e "INPUT_PASSWORD" -e "INPUT_SYNC" -e "INPUT_USE_INSECURE_CIPHER" -e "INPUT_CIPHER" -e "INPUT_TIMEOUT" -e "INPUT_COMMAND_TIMEOUT" -e "INPUT_KEY_PATH" -e "INPUT_FINGERPRINT" -e "INPUT_PROXY_HOST" -e "INPUT_PROXY_PORT" -e "INPUT_PROXY_USERNAME" -e "INPUT_PROXY_PASSWORD" -e "INPUT_PROXY_PASSPHRASE" -e "INPUT_PROXY_TIMEOUT" -e "INPUT_PROXY_KEY" -e "INPUT_PROXY_KEY_PATH" -e "INPUT_PROXY_FINGERPRINT" -e "INPUT_PROXY_CIPHER" -e "INPUT_PROXY_USE_INSECURE_CIPHER" -e "INPUT_SCRIPT_STOP" -e "INPUT_ENVS" -e "INPUT_ENVS_FORMAT" -e "INPUT_DEBUG" -e "INPUT_ALLENVS" -e "INPUT_REQUEST_PTY" -e "HOME" -e "GITHUB_JOB" -e "GITHUB_REF" -e "GITHUB_SHA" -e "GITHUB_REPOSITORY" -e "GITHUB_REPOSITORY_OWNER" -e "GITHUB_REPOSITORY_OWNER_ID" -e "GITHUB_RUN_ID" -e "GITHUB_RUN_NUMBER" -e "GITHUB_RETENTION_DAYS" -e "GITHUB_RUN_ATTEMPT" -e "GITHUB_ACTOR_ID" -e "GITHUB_ACTOR" -e "GITHUB_WORKFLOW" -e "GITHUB_HEAD_REF" -e "GITHUB_BASE_REF" -e "GITHUB_EVENT_NAME" -e "GITHUB_SERVER_URL" -e "GITHUB_API_URL" -e "GITHUB_GRAPHQL_URL" -e "GITHUB_REF_NAME" -e "GITHUB_REF_PROTECTED" -e "GITHUB_REF_TYPE" -e "GITHUB_WORKFLOW_REF" -e "GITHUB_WORKFLOW_SHA" -e "GITHUB_REPOSITORY_ID" -e "GITHUB_TRIGGERING_ACTOR" -e "GITHUB_WORKSPACE" -e "GITHUB_ACTION" -e "GITHUB_EVENT_PATH" -e "GITHUB_ACTION_REPOSITORY" -e "GITHUB_ACTION_REF" -e "GITHUB_PATH" -e "GITHUB_ENV" -e "GITHUB_STEP_SUMMARY" -e "GITHUB_STATE" -e "GITHUB_OUTPUT" -e "RUNNER_OS" -e "RUNNER_ARCH" -e "RUNNER_NAME" -e "RUNNER_ENVIRONMENT" -e "RUNNER_TOOL_CACHE" -e "RUNNER_TEMP" -e "RUNNER_WORKSPACE" -e "ACTIONS_RUNTIME_URL" -e "ACTIONS_RUNTIME_TOKEN" -e "ACTIONS_CACHE_URL" -e "ACTIONS_RESULTS_URL" -e "ACTIONS_ORCHESTRATION_ID" -e GITHUB_ACTIONS=true -e CI=true -v "/var/run/docker.sock":"/var/run/docker.sock" -v "/home/runner/work/_temp":"/github/runner_temp" -v "/home/runner/work/_temp/_github_home":"/github/home" -v "/home/runner/work/_temp/_github_workflow":"/github/workflow" -v "/home/runner/work/_temp/_runner_file_commands":"/github/file_commands" -v "/home/runner/work/portfolio-forum/portfolio-forum":"/github/workspace" 33b1c2:d0f3e093feec4adb91abbca76f725622
======CMD======
cd ***
docker compose -f compose.yaml -f compose.prod.yaml pull forum
docker compose -f compose.yaml -f compose.prod.yaml up -d --no-deps --force-recreate forum

======END======
2026/05/22 04:49:07 ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remainThere are two layers of automated deployment:

1. **`portfolio-infra`** — any push to `main` in this repo runs `docker compose -f compose.yaml -f compose.prod.yaml pull && docker compose -f compose.yaml -f compose.prod.yaml up -d --remove-orphans` to pick up config changes and any updated images.
2. **Per-service repos** (`portfolio-finance`, `portfolio-forum`, etc.) — each has its own `deploy.yml` that triggers after its `Build & Publish` workflow succeeds, SSHes in, and restarts **only that one container**.

### SSH keys — generate on the server, one per service

SSH in as the **`deploy` user** (not root) and generate one keypair per service. Separate keys mean a single compromised secret only affects one service.

```bash
for svc in infra identity forum finance household notifications math geography frontend gateway media; do
  ssh-keygen -t ed25519 -C "github-deploy-${svc}" -f ~/.ssh/deploy_${svc} -N ""
  cat ~/.ssh/deploy_${svc}.pub >> ~/.ssh/authorized_keys
done
```

The public keys are now already authorised. Next, print each private key to copy into GitHub:

```bash
for svc in infra identity forum finance household notifications math geography frontend gateway media; do
  echo "=== $svc ===" && cat ~/.ssh/deploy_${svc}
done
```

Once each private key is saved in GitHub secrets, **delete the private keys from the server** — they have no reason to live there:

```bash
rm ~/.ssh/deploy_*
```

### Add secrets to each GitHub repo

Go to **Settings → Secrets and variables → Actions → New repository secret** in each repo.

> **How to navigate there:** open the repo on GitHub → click **Settings** (top tab) → **Secrets and variables** (left sidebar) → **Actions** → **New repository secret**.

#### `portfolio-infra` — 5 secrets

Add these at `https://github.com/hkarpinen/portfolio-infra/settings/secrets/actions`:

| Secret | Value |
|---|---|
| `DEPLOY_HOST` | VPS IP or hostname (e.g. `hankkarpinen.com`) |
| `DEPLOY_USER` | SSH user (e.g. `deploy`) |
| `DEPLOY_KEY` | Contents of `~/.ssh/deploy_infra` (the private key you generated above) |
| `DEPLOY_PATH` | Absolute path to the infra folder — e.g. `/home/deploy/portfolio2/infra` |
| `DEPLOY_ENV` | Full contents of your filled-in `.env` — see the template below. The workflow writes this file to the server on every push to `main`. |

#### Per-service repos — 4 secrets each

Add the following to each repo at `https://github.com/hkarpinen/portfolio-<service>/settings/secrets/actions`:

Services: `portfolio-identity`, `portfolio-forum`, `portfolio-finance`, `portfolio-household`, `portfolio-notifications`, `portfolio-math`, `portfolio-geography`, `portfolio-frontend`, `portfolio-gateway`, `portfolio-media`.

| Secret | Value |
|---|---|
| `DEPLOY_HOST` | Same VPS IP or hostname |
| `DEPLOY_USER` | Same SSH user |
| `DEPLOY_KEY` | The private key **specific to that service** — e.g. contents of `~/.ssh/deploy_finance` for the finance repo |
| `DEPLOY_PATH` | Absolute path to the infra folder — e.g. `/home/deploy/portfolio2/infra` (must be absolute; `~` does not expand when passed via a secret) |

### DEPLOY_ENV template

To generate strong random values:

```bash
openssl rand -base64 48   # JWT secret
openssl rand -hex 20      # DB passwords
```

```dotenv
# PostgreSQL superuser (used only for init and admin)
POSTGRES_PASSWORD=changeme

# Per-service DB users
IDENTITY_DB_PASSWORD=changeme-identity
FORUM_DB_PASSWORD=changeme-forum
FINANCE_DB_PASSWORD=changeme-finance
NOTIFICATIONS_DB_PASSWORD=changeme-notifications
HOUSEHOLD_DB_PASSWORD=changeme-household
MEDIA_DB_PASSWORD=changeme-media

# Base64-encoded PKCS#8 PEM of an EC P-256 private key. Only identity holds it; every other
# service verifies against the public half it publishes at /.well-known/jwks.json.
#   openssl ecparam -genkey -name prime256v1 -noout | openssl pkcs8 -topk8 -nocrypt | base64
JWT_PRIVATE_KEY_PEM=

# RabbitMQ — do not use guest/guest in production
RABBITMQ_USER=portfolio
RABBITMQ_PASSWORD=changeme-rabbitmq

# Connection strings — wired to per-service users above
IDENTITY_CONN=Host=postgres;Database=identity_db;Username=identity_user;Password=changeme-identity
FORUM_CONN=Host=postgres;Database=forum_db;Username=forum_user;Password=changeme-forum
FINANCE_CONN=Host=postgres;Database=finance_db;Username=finance_user;Password=changeme-finance
NOTIFICATIONS_CONN=Host=postgres;Database=notifications_db;Username=notifications_user;Password=changeme-notifications
HOUSEHOLD_CONN=Host=postgres;Database=household_db;Username=household_user;Password=changeme-household
MEDIA_CONN=Host=postgres;Database=media_db;Username=media_user;Password=changeme-media

# Plaid — https://dashboard.plaid.com/team/keys
PLAID_CLIENT_ID=
PLAID_SECRET=
PLAID_ENVIRONMENT=sandbox
PLAID_WEBHOOK_URL=https://hankkarpinen.com/api/finance/connections/webhook

# OpenWeatherMap — https://openweathermap.org/api
OPENWEATHERMAP_API_KEY=

# SMTP relay
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USERNAME=postmaster@hankkarpinen.com
EMAIL_PASSWORD=changeme-smtp
EMAIL_FROM_ADDRESS=noreply@hankkarpinen.com
EMAIL_FROM_NAME=hankkarpinen.com
EMAIL_BASE_URL=https://hankkarpinen.com

# Storage / media public URLs
STORAGE_PUBLIC_BASE_URL=https://hankkarpinen.com/uploads/avatars
MEDIA_PUBLIC_BASE_URL=https://hankkarpinen.com/uploads/forum

# reCAPTCHA — https://www.google.com/recaptcha/admin
RECAPTCHA_SITE_KEY=
RECAPTCHA_SECRET_KEY=

```

---

## 6. Clone the Repository

```bash
git clone https://github.com/hkarpinen/portfolio2.git ~/portfolio2
cd ~/portfolio2/infra
```

---

## 7. Create the `.env` File

The GitHub Actions workflow writes `.env` automatically on every push — but the very first deploy happens manually, so you need to create it once.

Copy the example and fill in the same values you put in the `DEPLOY_ENV` secret:

```bash
cp ~/portfolio2/infra/.env.example ~/portfolio2/infra/.env
nano ~/portfolio2/infra/.env
```

---

## 8. Pull Images and Start the Stack

```bash
docker compose -f compose.yaml -f compose.prod.yaml pull
docker compose -f compose.yaml -f compose.prod.yaml up -d --remove-orphans
```

Check all services came up cleanly:

```bash
docker compose -f compose.yaml -f compose.prod.yaml ps
```

All services should show `healthy` or `running`. If something is stuck, inspect its logs:

```bash
docker compose -f compose.yaml -f compose.prod.yaml logs identity --tail=50
```

---

## 9. Verify the Deployment

```bash
# Frontend via the gateway
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

## 10. HTTPS with Let's Encrypt

The gateway binds 443 only when `Tls__CertPath` and `Tls__KeyPath` point at real files, so the certificates must exist before the stack starts.

### Prerequisites: DNS must point to this VPS first

Certbot proves domain ownership by having the CA download a challenge file from your server on port 80. **If the domain doesn't resolve to this VPS yet, certbot will fail with a "challenge files" error.**

1. Buy the domain and go to your registrar's DNS settings (or your DNS provider — Cloudflare, Route 53, etc.)
2. Add an **A record** pointing `hankkarpinen.com` → your VPS IP
3. Add another **A record** (or CNAME) for `www.hankkarpinen.com` → your VPS IP
4. Wait for DNS to propagate — usually a few minutes, sometimes up to an hour

Verify before proceeding:

```bash
# Should return your VPS IP
dig +short hankkarpinen.com
dig +short www.hankkarpinen.com
```

### First-time certificate issuance

Once DNS resolves correctly, obtain certs using certbot standalone **before** starting the full stack (port 80 must be free):

```bash
sudo apt install -y certbot
sudo certbot certonly --standalone -d hankkarpinen.com -d www.hankkarpinen.com
```

Certs land at `/etc/letsencrypt/live/hankkarpinen.com/`. The gateway mounts `/etc/letsencrypt` read-only, so the paths are wired up automatically.

Then start the stack normally:

```bash
docker compose -f compose.yaml -f compose.prod.yaml pull
docker compose -f compose.yaml -f compose.prod.yaml up -d --remove-orphans
```

### Certificate renewal

Certbot installs a systemd timer that auto-renews before expiry. The gateway reads the certificate
files at startup, so the hook restarts it:

```bash
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/restart-gateway.sh > /dev/null <<'EOF'
#!/bin/sh
cd /home/deploy/portfolio2/infra
docker compose -f compose.yaml -f compose.prod.yaml restart gateway
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-gateway.sh
```

If an older `reload-nginx.sh` hook is still there, delete it — there is no nginx container to signal.

Certbot renews via the HTTP-01 ACME challenge using the `/var/www/certbot` webroot volume, which the
gateway serves at `/.well-known/acme-challenge/` on port 80.

Test renewal dry-run:

```bash
sudo certbot renew --dry-run
```

---

## 11. Useful Day-to-Day Commands

Both files, every time — `compose.yaml` alone declares no ports, no TLS and no production
environment. Worth an alias:

```bash
alias dcp='docker compose -f compose.yaml -f compose.prod.yaml'
```

```bash
# View all service statuses
dcp ps

# Follow logs for all services
dcp logs -f

# Follow logs for a specific service
dcp logs -f identity

# Pull latest images and redeploy
dcp pull && dcp up -d --remove-orphans

# Stop the entire stack
dcp down

# Stop the stack and wipe all data (destructive!)
dcp down -v

# Restart a single service
dcp restart forum

# Open a shell inside a running container
dcp exec identity bash
```

---


