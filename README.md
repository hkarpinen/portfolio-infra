# portfolio-infra

Docker Compose stack for the portfolio. Pulls pre-built images from `ghcr.io` and wires up all services.

## Services

| Service | Image | Port |
|---|---|---|
| `identity` | `ghcr.io/hkarpinen/portfolio-identity` | 8081 |
| `forum` | `ghcr.io/hkarpinen/portfolio-forum` | 8082 |
| `bills` | `ghcr.io/hkarpinen/portfolio-bills` | 8083 |
| `frontend` | `ghcr.io/hkarpinen/portfolio-frontend` | 3000 |
| `nginx` | `nginx:alpine` | 80 (reverse proxy) |
| `postgres` | `postgres:17` | (internal) |
| `rabbitmq` | `rabbitmq:3-management` | 5672, 15672 |
| `mailpit` | `axllent/mailpit` | 8025 (web UI), 1025 (SMTP) |

## Quick start

```bash
cp .env.example .env
# Edit .env — change POSTGRES_PASSWORD and JWT_SECRET at minimum
docker compose pull
docker compose up -d
```

App available at [http://localhost](http://localhost).  
RabbitMQ management UI at [http://localhost:15672](http://localhost:15672).  
Mailpit (dev email) at [http://localhost:8025](http://localhost:8025).

## Pinning a specific image version

By default all service images use `:latest`. Override via env vars:

```env
IDENTITY_IMAGE=ghcr.io/hkarpinen/portfolio-identity:abc1234
FORUM_IMAGE=ghcr.io/hkarpinen/portfolio-forum:abc1234
BILLS_IMAGE=ghcr.io/hkarpinen/portfolio-bills:abc1234
FRONTEND_IMAGE=ghcr.io/hkarpinen/portfolio-frontend:abc1234
```

## Files

| File | Description |
|---|---|
| `compose.yaml` | Service definitions |
| `nginx.conf` | Reverse proxy routing rules |
| `init-databases.sql` | Creates `identity_db`, `forum_db`, `bills_db` on first boot |
| `.env.example` | Template for required secrets |
