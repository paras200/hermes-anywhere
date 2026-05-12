.PHONY: help install check-update update doctor backup restore install-cron up down logs

# Default goal
.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install: ## First-time install: create .env, pull latest image, start containers
	@test -f .env || (cp .env.example .env && echo "Created .env from .env.example — edit it to add your OPENROUTER_API_KEY" && chmod 600 .env)
	@mkdir -p hermes-data && chmod 700 hermes-data
	@docker compose pull
	@docker compose up -d
	@echo "Hermes is starting. Dashboard: http://localhost:9119 (allow ~60s on first boot)"

check-update: ## Check Docker Hub for a newer Hermes image digest
	@scripts/check-update.sh

update: ## Pull the newest image digest and restart (no file edits)
	@docker compose pull
	@docker compose up -d
	@echo "Updated to current digest of $$(grep -E '^HERMES_VERSION=' .env 2>/dev/null | cut -d= -f2 || echo latest)"

pin: ## Pin to a specific tag in all repo files. Pass TAG=<tag>
	@test -n "$(TAG)" || (echo "Usage: make pin TAG=latest | v2026.4.30 | sha-abc1234" && exit 1)
	@scripts/update.sh $(TAG)

doctor: ## Run health checks on the local Hermes deployment
	@scripts/doctor.sh

backup: ## Create encrypted backup of hermes-data/ (set BACKUP_PASSPHRASE)
	@scripts/backup.sh

restore: ## Restore hermes-data/ from a backup. Pass FILE=path/to/backup.tgz.gpg
	@test -n "$(FILE)" || (echo "Usage: make restore FILE=hermes-data.YYYY-MM-DD.tgz.gpg" && exit 1)
	@scripts/restore.sh $(FILE)

install-cron: ## Install systemd timer for daily upstream version check (run on VM as root)
	@sudo bash scripts/install-cron.sh

up: ## docker compose up -d
	@docker compose up -d

down: ## docker compose down (preserves hermes-data/)
	@docker compose down

logs: ## Tail logs from both containers
	@docker compose logs -f --tail=100
