# Public Kheeper images

Turn-key [bootc](https://bootc-dev.github.io/) images for self-hosting popular open-source software on your own cloud or bare metal.
Each image is a single immutable OS that boots, provisions TLS, opens the right firewall ports, and starts the service.


## Images

| Image | What it is |
| ----- | ---------- |
| [Forgejo](forgejo) | Self-hosted Git forge. Backed by a local Postgres, TLS via Caddy, git-over-SSH. |
| [Gemma 4](gemma4) | Google's 31B open-weight LLM served as an OpenAI-compatible API by vLLM. TLS via Caddy and Grafana dashboard included. |
| [OpenFGA](openfga) | Fine-grained authorization service with a friendly modeling language. Local Postgres for state, TLS via Caddy, Grafana dashboard, bearer-token auth. |
| [Pi-hole](pihole) | Network-wide DNS sinkhole and ad-blocker. Admin UI served over TLS; DNS locked down by source CIDR. |
| [Postgres](postgres) | PostgreSQL with WAL-G base backups and WAL archiving, `postgres_exporter` metrics in Grafana, and a Let's Encrypt cert on `:5432`. |

Or use these as inspiration to [make your own bootable images](https://kheeper.com/docs/getting-started/build-and-push).

## Prerequisites

1. Create an account on [kheeper.com](https://kheeper.com)
1. [Install the kheeper CLI](https://kheeper.com/docs/getting-started/install)
1. [Log in to the kheeper CLI](https://kheeper.com/docs/getting-started/login)
