## Docker
To install docker:
make install-docker
make init-docker
make plan-docker
make apply-docker

## PostgreSQL TLS
Vault writes `server.crt` and `server.key` under `terraform/docker`; rsync them to `/etc/certs/` on the Docker host. Set the key to `root:999` and mode `0640` for the `postgres:18` container.

Copy `terraform/vault/root_2026_ca.crt` to `~/.postgresql/root.crt` on the client and set mode `0600`.

Connect with `psql "host=docker.homelab.lan user=postgres dbname=postgres sslmode=verify-full"`.