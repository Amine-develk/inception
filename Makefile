COMPOSE_FILE = srcs/docker-compose.yml
COMPOSE      = docker compose -f $(COMPOSE_FILE)

DATA_DIR := $(shell grep -E '^DATA_DIR=' srcs/.env | cut -d '=' -f2)

.PHONY: all up down stop start restart clean fclean re data_dirs logs ps

all: up

up: data_dirs
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart: down up

clean: down

fclean:
	$(COMPOSE) down --volumes --rmi all
	sudo rm -rf $(DATA_DIR)

re: fclean up

data_dirs:
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/db

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps