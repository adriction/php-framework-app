DC = docker compose -f docker/docker-compose.yml --env-file .env

.PHONY: install up down build restart sh logs composer console db-shell

install: ## Premiere installation : .env, build, up, composer install
	@test -f .env || cp .env.example .env
	$(DC) build
	$(MAKE) up
	$(DC) exec php composer install
	@echo ""
	@echo "-> http://localhost:$$(grep -oP '(?<=APP_PORT=).*' .env)"

up: ## Demarre la stack (arriere-plan)
	$(DC) up -d
	# var/ est bind-mount depuis l'hote (uid variable) mais ecrit par www-data
	# dans le conteneur (cache Twig, logs) : on force des permissions ouvertes
	# pour eviter des echecs d'ecriture silencieux.
	$(DC) exec php chmod -R 0777 var/cache var/log

down: ## Arrete et supprime les conteneurs
	$(DC) down

build: ## Rebuild les images
	$(DC) build

restart: ## Redemarre la stack
	$(DC) restart

sh: ## Shell dans le conteneur php
	$(DC) exec php sh

logs: ## Suit les logs de tous les conteneurs
	$(DC) logs -f

composer: ## make composer c="require vendor/package"
	$(DC) exec php composer $(c)

console: ## make console c="route:list"
	$(DC) exec php php bin/console $(c)

db-shell: ## Client SQL interactif dans le conteneur mariadb
	$(DC) exec mariadb sh -c 'mariadb -u"$$MARIADB_USER" -p"$$MARIADB_PASSWORD" "$$MARIADB_DATABASE"'
