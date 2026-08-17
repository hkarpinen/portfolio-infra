# portfolio-infra

Docker Compose stack for the portfolio. Pulls pre-built images from `ghcr.io` and wires up all services.

## Services

| Service | Image | Port |
|---|---|---|
| `gateway` | `ghcr.io/hkarpinen/portfolio-gateway` | 80, 443 in prod; 8088 in dev — the edge and the route table |
| `identity` | `ghcr.io/hkarpinen/portfolio-identity` | 8081 (dev only) |
| `forum` | `ghcr.io/hkarpinen/portfolio-forum` | 8082 (dev only) |
| `finance` | `ghcr.io/hkarpinen/portfolio-finance` | 8083 (dev only) |
| `notifications` | `ghcr.io/hkarpinen/portfolio-notifications` | 8084 (dev only) |
| `household` | `ghcr.io/hkarpinen/portfolio-household` | 8085 (dev only) |
| `math` | `ghcr.io/hkarpinen/portfolio-math` | 8086 (dev only) |
| `geography` | `ghcr.io/hkarpinen/portfolio-geography` | 8087 (dev only) |
| `frontend` | `ghcr.io/hkarpinen/portfolio-frontend` | 3000 (prod only — run `npm run dev` locally instead) |
| `postgres` | `postgres:17` | (internal) |
| `rabbitmq` | `rabbitmq:3-management` | 5672, 15672 |
| `mailpit` | `axllent/mailpit` | 8025 (web UI), 1025 (SMTP) |

## Quick start

### Production (pull published images)

```bash
cp .env.example .env
# Edit .env — POSTGRES_PASSWORD and JWT_PRIVATE_KEY_PEM at minimum.
# Generate the signing key with:
#   openssl ecparam -genkey -name prime256v1 -noout | openssl pkcs8 -topk8 -nocrypt | base64
docker compose -f compose.yaml -f compose.prod.yaml pull
docker compose -f compose.yaml -f compose.prod.yaml up -d
```

### Local development

Run the backends in Docker, the frontend locally with hot reload:

```bash
# Terminal 1 — infrastructure, backends and the gateway (no frontend container)
docker compose -f compose.yaml -f compose.dev.yaml up -d

# Terminal 2 — Next.js dev server with hot reload
cd ../frontend
npm install
npm run dev
```

`next.config.mjs` rewrites `/api/*` to the gateway on :8088 — one line, one destination. The gateway holds the only route table, in `gateway/src/Gateway/appsettings.json`.

App available at [http://localhost:3000](http://localhost:3000) in dev.  
RabbitMQ management UI at [http://localhost:15672](http://localhost:15672).  
Mailpit (dev email) at [http://localhost:8025](http://localhost:8025).

## Pinning a specific image version

By default all service images use `:latest`. Override via env vars:

```env
IDENTITY_IMAGE=ghcr.io/hkarpinen/portfolio-identity:abc1234
FORUM_IMAGE=ghcr.io/hkarpinen/portfolio-forum:abc1234
FINANCE_IMAGE=ghcr.io/hkarpinen/portfolio-finance:abc1234
FRONTEND_IMAGE=ghcr.io/hkarpinen/portfolio-frontend:abc1234
```

## Files

| File | Description |
|---|---|
| `compose.yaml` | The stack and the flow. Nothing environment-specific |
| `compose.dev.yaml` | Dev facts, layered on the base: builds from source, publishes ports, loosens rate limits, no TLS |
| `compose.prod.yaml` | Production facts: 80/443, the certificate paths, the upload volumes, the real secrets |
| `init-databases.sql` | Creates `identity_db`, `forum_db`, `finance_db` on first boot |
| `.env.example` | Template for required secrets |
