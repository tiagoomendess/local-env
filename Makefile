.PHONY: help start stop restart status logs clean rebuild shell mysql-shell redis-shell start-localstack stop-localstack restart-localstack localstack-logs s3-ls s3-shell sqs-ls sns-ls

# Default target
.DEFAULT_GOAL := help

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Docker Compose command
DC := docker-compose

# Help target
help: ## Show this help message
	@echo "$(YELLOW)Available commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# Start services
start: ## Start all services in detached mode
	@echo "$(GREEN)Starting all services...$(NC)"
	$(DC) up -d
	@echo "$(GREEN)All services started!$(NC)"
	@$(MAKE) status

start-mysql: ## Start only MySQL
	@echo "$(GREEN)Starting MySQL...$(NC)"
	$(DC) up -d mysql
	@echo "$(GREEN)MySQL started!$(NC)"

start-redis: ## Start only Redis
	@echo "$(GREEN)Starting Redis...$(NC)"
	$(DC) up -d redis
	@echo "$(GREEN)Redis started!$(NC)"

start-localstack: ## Start only LocalStack (S3, SQS, SNS)
	@echo "$(GREEN)Starting LocalStack...$(NC)"
	$(DC) up -d localstack
	@echo "$(GREEN)LocalStack started!$(NC)"

# Stop services
stop: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	$(DC) stop
	@echo "$(YELLOW)All services stopped!$(NC)"

stop-mysql: ## Stop only MySQL
	@echo "$(YELLOW)Stopping MySQL...$(NC)"
	$(DC) stop mysql
	@echo "$(YELLOW)MySQL stopped!$(NC)"

stop-redis: ## Stop only Redis
	@echo "$(YELLOW)Stopping Redis...$(NC)"
	$(DC) stop redis
	@echo "$(YELLOW)Redis stopped!$(NC)"

stop-localstack: ## Stop only LocalStack
	@echo "$(YELLOW)Stopping LocalStack...$(NC)"
	$(DC) stop localstack
	@echo "$(YELLOW)LocalStack stopped!$(NC)"

# Restart services
restart: ## Restart all services
	@echo "$(YELLOW)Restarting all services...$(NC)"
	$(DC) restart
	@echo "$(GREEN)All services restarted!$(NC)"

restart-mysql: ## Restart only MySQL
	@echo "$(YELLOW)Restarting MySQL...$(NC)"
	$(DC) restart mysql
	@echo "$(GREEN)MySQL restarted!$(NC)"

restart-redis: ## Restart only Redis
	@echo "$(YELLOW)Restarting Redis...$(NC)"
	$(DC) restart redis
	@echo "$(GREEN)Redis restarted!$(NC)"

restart-localstack: ## Restart only LocalStack
	@echo "$(YELLOW)Restarting LocalStack...$(NC)"
	$(DC) restart localstack
	@echo "$(GREEN)LocalStack restarted!$(NC)"

# Status and logs
status: ## Show status of all services
	@echo "$(GREEN)Service status:$(NC)"
	$(DC) ps

logs: ## View logs for all services
	$(DC) logs -f

mysql-logs: ## View MySQL logs
	$(DC) logs -f mysql

redis-logs: ## View Redis logs
	$(DC) logs -f redis

localstack-logs: ## View LocalStack logs
	$(DC) logs -f localstack

# Shell access
mysql-shell: ## Open MySQL CLI
	@echo "$(GREEN)Connecting to MySQL...$(NC)"
	$(DC) exec mysql mysql -u root -p

mysql-shell-dev: ## Open MySQL CLI as dev user
	@echo "$(GREEN)Connecting to MySQL as dev user...$(NC)"
	$(DC) exec mysql mysql -u devuser -p

redis-shell: ## Open Redis CLI
	@echo "$(GREEN)Connecting to Redis...$(NC)"
	$(DC) exec redis redis-cli -a $$(grep REDIS_PASSWORD .env | cut -d '=' -f2)

s3-ls: ## List all S3 buckets in LocalStack
	@echo "$(GREEN)Listing S3 buckets...$(NC)"
	$(DC) exec localstack awslocal s3 ls

sqs-ls: ## List all SQS queues in LocalStack
	@echo "$(GREEN)Listing SQS queues...$(NC)"
	$(DC) exec localstack awslocal sqs list-queues

sns-ls: ## List all SNS topics in LocalStack
	@echo "$(GREEN)Listing SNS topics...$(NC)"
	$(DC) exec localstack awslocal sns list-topics

s3-shell: ## Open bash in LocalStack container
	@echo "$(GREEN)Opening LocalStack shell...$(NC)"
	$(DC) exec localstack bash

# Bash shell in containers
bash-mysql: ## Open bash in MySQL container
	$(DC) exec mysql bash

bash-redis: ## Open bash in Redis container
	$(DC) exec redis sh

# Data management
clean: ## Stop and remove containers (keeps data volumes)
	@echo "$(RED)Stopping and removing containers...$(NC)"
	$(DC) down
	@echo "$(RED)Containers removed, data volumes preserved!$(NC)"

clean-all: ## Remove everything including data volumes (WARNING: deletes all data!)
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DC) down -v; \
		echo "$(RED)All containers and volumes removed!$(NC)"; \
	else \
		echo "$(GREEN)Operation cancelled.$(NC)"; \
	fi

# Backup and restore
backup-mysql: ## Backup MySQL database to file
	@echo "$(GREEN)Backing up MySQL database...$(NC)"
	$(DC) exec mysql mysqldump -u root -p$$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) \
		$$(grep MYSQL_DATABASE .env | cut -d '=' -f2) > backups/mysql_backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)Backup created in backups/ folder!$(NC)"

# Rebuild
build: ## Build or rebuild all services
	@echo "$(GREEN)Building services...$(NC)"
	$(DC) build

rebuild: ## Rebuild and restart all services
	@echo "$(GREEN)Rebuilding services...$(NC)"
	$(DC) up -d --build
	@echo "$(GREEN)Services rebuilt and restarted!$(NC)"

# Development helpers
dev-start: start ## Start services and tail logs
	@echo "$(GREEN)Showing logs...$(NC)"
	$(DC) logs -f

dev-reset: clean-all start ## Complete reset: remove everything and start fresh
	@echo "$(GREEN)Environment reset complete!$(NC)"

# Check service health
health: ## Check health of all services
	@echo "$(GREEN)Checking service health...$(NC)"
	$(DC) ps --format "table {{.Name}}\t{{.Status}}"

wait-mysql: ## Wait for MySQL to be healthy
	@echo "$(YELLOW)Waiting for MySQL to be ready...$(NC)"
	@until $(DC) exec mysql mysqladmin ping -h localhost --silent; do \
		echo "$(YELLOW)Waiting...$(NC)"; \
		sleep 2; \
	done
	@echo "$(GREEN)MySQL is ready!$(NC)"
