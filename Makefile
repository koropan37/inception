COMPOSE_FILE := ./srcs/docker-compose.yml
VOLUME_DIR := ~/data

.PHONY: all build up down logs ps clean fclean re

all: build up

build: $(VOLUME_DIR)
	@echo "Building images..."
	@docker compose -f $(COMPOSE_FILE) build

up: $(VOLUME_DIR)
	@echo "Starting containers..."
	@docker compose -f $(COMPOSE_FILE) up -d

down:
	@echo "Stopping containers..."
	@docker compose -f $(COMPOSE_FILE) down

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

ps:
	@docker compose -f $(COMPOSE_FILE) ps

clean: down
	@echo "Cleaning containers and images..."
	@docker compose -f $(COMPOSE_FILE) down --rmi local --remove-orphans

fclean: clean
	@echo "Removing volumes..."
	@docker compose -f $(COMPOSE_FILE) down -v
	@sudo rm -rf $(VOLUME_DIR)

re: fclean all

$(VOLUME_DIR):
	@mkdir -p $@/mariadb
	@mkdir -p $@/wordpress