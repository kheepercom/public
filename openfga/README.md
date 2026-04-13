# OpenFGA

[Homepage](https://openfga.dev)

[GitHub](https://github.com/openfga)

> OpenFGA is an open-source authorization solution that allows developers to build granular access control using an easy-to-read modeling language and friendly APIs.

Operate OpenFGA on your server with persistence provided by Postgres andautomatic TLS provided by [Caddy](https://caddyserver.com).

## Launch

Follow the [cloud] or [bare metal] guide to register a host, and set a DNS record to resolve to the host.

```
kheeper start kheeper.com/public/openfga:latest
```

That will save a default config file to ./config.json.
Edit that file, ensuring the provided domain re

```
ORG=my-organization
HOST=my-openfga

kheeper releases create $ORG/$HOST:v1 \
    --image kheeper.com/public/openfga:latest \
    --config-file config.json \
    --activate
```
