# CLAUDE.md

Ce fichier guide Claude Code (claude.ai/code) lors du travail sur ce dépôt.

## Projet

**php-framework-app** est une application construite sur [`adrien/php-framework`](../php-framework), un framework PHP personnel minimaliste (PHP 8.4, MVC en couches strictes, peu de dépendances). Ce dépôt contient le code applicatif (`src/App/`, `templates/`, config, Docker) ; toute la logique réutilisable (routing, DI, Twig, DBAL, erreurs, plugins, CLI) vit dans la librairie, importée via Composer.

**Documentation du framework** (référence pour l'architecture, les conventions, comment ajouter une route/un Controller/Service/Repository, écrire un plugin, etc.) : [`../php-framework/docs/index.html`](../php-framework/docs/index.html) — à consulter systématiquement avant d'ajouter une feature ici, plutôt que de redéfinir des conventions.

## Comment le framework est chargé

`composer.json` déclare un repository local de type `path` :

```json
"repositories": [{ "type": "path", "url": "../php-framework" }]
```

`vendor/adrien/php-framework` est donc un **lien symbolique** vers `/home/adrien/Apps/php-framework` (à l'intérieur du conteneur `php`, ce lien pointe vers `/var/www/php-framework`, monté par `docker/docker-compose.yml` — voir le commentaire dans ce fichier). **Toute modification faite directement dans `/home/adrien/Apps/php-framework/src/Framework/` est donc reflétée immédiatement ici**, sans réinstallation — pratique pour développer les deux en parallèle, mais à garder en tête : un bug qui semble venir de cette app peut en réalité venir d'une modif récente du framework.

Si le framework a un `composer.json` modifié (nouvelle dépendance, etc.), relancer `make composer c="update adrien/php-framework"`.

## Stack

PHP 8.4, nginx, MariaDB 11 — tout dans Docker (`docker/docker-compose.yml`). **Ne jamais exécuter `composer`/`php` sur l'hôte** — toujours via le `Makefile` (`make composer c="..."`, `make console c="..."`, `make sh`).

## Architecture — MVC en couches strictes

Héritée du framework, **non négociable** : `Controller → Service → Repository → DB`.

- `src/App/Controller/` — étend `Framework\Controller\AbstractController`. Jamais de SQL, jamais de logique métier.
- `src/App/Service/` — logique métier, appelle un ou plusieurs Repositories.
- `src/App/Repository/` — étend `Framework\Database\AbstractRepository`. Seul endroit où une requête SQL doit apparaître.

Détails et exemples complets : [`../php-framework/docs/controllers.html`](../php-framework/docs/controllers.html).

## Commandes utiles

```bash
make install                          # premiere installation (build, up, composer install)
make up / make down / make restart
make sh                               # shell dans le conteneur php
make logs
make composer c="require vendor/package"
make console c="route:list"
make console c="plugin:install <nom>"
make console c="make:controller <Nom>"
make db-shell
```

## Plugins de cette app

Les plugins installés ici (`plugins-registry.json`, `plugins/`) sont indépendants de ceux du framework — voir [`../php-framework/docs/plugins.html`](../php-framework/docs/plugins.html) pour le format et le cycle de vie (`Framework\Plugin\PluginManager`, réutilisé tel quel depuis le vendor).

## Ports locaux (Docker)

`APP_PORT=8092` et `DB_EXPOSED_PORT=3311` (définis dans `.env`) ont été choisis pour ne pas entrer en conflit avec d'autres projets déjà lancés localement sur cette machine (dont `php-framework` lui-même, qui utilisait 8091/3310 avant de devenir une librairie pure sans stack propre). Vérifier les ports libres (`ss -tlnp`) avant d'en ajouter un nouveau.
