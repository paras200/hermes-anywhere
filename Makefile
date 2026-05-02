.PHONY: help check-update update doctor backup restore install-cron up down logs

# Default goal
.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

check-update: ## Check Docker Hub for a newer Hermes version
	@scripts/check-update.sh

update: ## Bump version in all files. Pass VERSION=vYYYY.M.D
	@test -n "$(VERSION)" || (echo "Usage: make update VERSION=v2026.4.30" && exit 1)
	@scripts/update.sh $(VERSION)

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
