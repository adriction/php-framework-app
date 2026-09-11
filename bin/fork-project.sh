#!/usr/bin/env bash
#
# Cree un nouveau projet independant (fork git reel) a partir de cet app de
# reference (php-framework-app), en dossier frere.
#
# Usage : bin/fork-project.sh <nom-du-projet> [app-port] [db-port]
#   bin/fork-project.sh adrictionv6
#   bin/fork-project.sh adrictionv6 8093 3312
#
# Ce que ca fait :
#   - git clone (historique complet preserve) vers ../<nom-du-projet>
#   - remotes : "upstream" (fetch-only, pointe sur ce depot) + "origin" (vers
#     le nouveau depot GitHub, a creer toi-meme AVANT de push — ce script ne
#     cree rien sur GitHub, pas de gh CLI dispo)
#   - adrien/php-framework passe d'un repository Composer "path" (symlink dev
#     local) a un vrai lien "vcs" (git clone via SSH, agent forwarding) : le
#     nouveau projet ne reflete plus les modifs locales de php-framework, il
#     faut "composer update adrien/php-framework" pour recuperer une evolution
#   - Dockerfile : ajoute openssh-client (necessaire au clone vcs SSH)
#   - docker-compose.yml : nom de projet Docker + ports dedies, mount de
#     l'agent SSH de l'hote a la place du mount du depot php-framework
#   - composer.json / README.md / CLAUDE.md / .env.example / templates :
#     identite renommee (nom, ports, description)
#
# A savoir : ce script patche des chaines EXACTES tirees du contenu actuel de
# php-framework-app — s'il evolue (docker-compose.yml, composer.json...), ce
# script doit etre mis a jour en meme temps.
set -euo pipefail

NAME="${1:?Usage: bin/fork-project.sh <nom-du-projet> [app-port] [db-port]}"
APP_PORT="${2:-}"
DB_PORT="${3:-}"

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(dirname "$SOURCE_DIR")"
TARGET_DIR="$PARENT_DIR/$NAME"
SOURCE_PROJECT_NAME="$(basename "$SOURCE_DIR")"

if [ -e "$TARGET_DIR" ]; then
    echo "Erreur : $TARGET_DIR existe deja." >&2
    exit 1
fi

free_port() {
    local port=$1
    while ss -tln 2>/dev/null | grep -q ":$port "; do
        port=$((port + 1))
    done
    echo "$port"
}

[ -z "$APP_PORT" ] && APP_PORT=$(free_port 8093)
[ -z "$DB_PORT" ] && DB_PORT=$(free_port 3312)

SOURCE_REMOTE_URL="$(git -C "$SOURCE_DIR" remote get-url origin)"
GITHUB_ORG="$(echo "$SOURCE_REMOTE_URL" | sed -E 's#.*[:/]([^/]+)/[^/]+\.git#\1#')"

FRAMEWORK_DIR="$PARENT_DIR/php-framework"
if [ -d "$FRAMEWORK_DIR/.git" ]; then
    FRAMEWORK_REMOTE_URL="$(git -C "$FRAMEWORK_DIR" remote get-url origin)"
else
    FRAMEWORK_REMOTE_URL="git@github.com:$GITHUB_ORG/php-framework.git"
fi

DB_NAME_SAFE="$(echo "$NAME" | tr '-' '_')"

echo "==> Clonage de $SOURCE_DIR vers $TARGET_DIR"
git clone "$SOURCE_DIR" "$TARGET_DIR"
cd "$TARGET_DIR"

echo "==> Remotes (upstream fetch-only vers $SOURCE_PROJECT_NAME, origin vers $NAME)"
git remote rename origin upstream
git remote set-url upstream "$SOURCE_REMOTE_URL"
git remote set-url --push upstream DISABLED
git remote add origin "git@github.com:$GITHUB_ORG/$NAME.git"

echo "==> composer.json (vrai lien vcs vers adrien/php-framework)"
cat > composer.json <<JSON
{
    "name": "adrien/$NAME",
    "description": "Projet independant, forke depuis $SOURCE_PROJECT_NAME, construit sur adrien/php-framework.",
    "type": "project",
    "license": "proprietary",
    "require": {
        "php": ">=8.4",
        "adrien/php-framework": "dev-main"
    },
    "repositories": [
        {
            "type": "vcs",
            "url": "$FRAMEWORK_REMOTE_URL"
        }
    ],
    "autoload": {
        "psr-4": {
            "App\\\\": "src/App/"
        }
    },
    "config": {
        "sort-packages": true,
        "optimize-autoloader": true,
        "preferred-install": {
            "adrien/php-framework": "source",
            "*": "dist"
        }
    },
    "minimum-stability": "stable",
    "prefer-stable": true
}
JSON

# composer.lock herite du clone resout encore adrien/php-framework en "path"
# (l'ancienne resolution) : composer install s'y fierait au lieu de lire le
# nouveau composer.json. Supprime pour forcer une resolution fraiche (vcs).
rm -f composer.lock

echo "==> Dockerfile (client SSH pour le clone vcs)"
perl -0pi -e 's/RUN apk add --no-cache git icu-dev libzip-dev \\\n    && docker-php-ext-install pdo_mysql intl zip opcache/RUN apk add --no-cache git openssh-client icu-dev libzip-dev \\\n    && docker-php-ext-install pdo_mysql intl zip opcache \\\n    && mkdir -p -m 0700 \/root\/.ssh \\\n    && ssh-keyscan -t ed25519 github.com >> \/root\/.ssh\/known_hosts/' docker/php/Dockerfile

echo "==> docker-compose.yml (nom de projet, ports, agent SSH au lieu du mount php-framework)"
perl -0pi -e "s/name: $SOURCE_PROJECT_NAME/name: $NAME/" docker/docker-compose.yml
# Remplace tout le bloc "- ../:/var/www/html" (+ ses eventuels commentaires) ..
# jusqu'au mount du depot php-framework inclus, par le mount de l'agent SSH.
perl -0pi -e 's#      - \.\./:/var/www/html\n(?:      \#.*\n)*      - \.\./\.\./php-framework:/var/www/php-framework\n#      - ../:/var/www/html\n      - \${SSH_AUTH_SOCK}:/ssh-agent\n#' docker/docker-compose.yml
perl -0pi -e 's#(      - \$\{SSH_AUTH_SOCK\}:/ssh-agent\n)    env_file:#$1    environment:\n      SSH_AUTH_SOCK: /ssh-agent\n    env_file:#' docker/docker-compose.yml
sed -i "s/APP_PORT:-8092/APP_PORT:-$APP_PORT/" docker/docker-compose.yml
sed -i "s/DB_EXPOSED_PORT:-3311/DB_EXPOSED_PORT:-$DB_PORT/" docker/docker-compose.yml
sed -i "s/DB_NAME:-php_framework_app/DB_NAME:-$DB_NAME_SAFE/" docker/docker-compose.yml

echo "==> .env.example"
# Remplacement global des numeros de port (valeurs ET commentaires qui les
# citent) : 8092/3311 sont ceux de $SOURCE_PROJECT_NAME, jamais reutilises ici.
sed -i \
    -e "s/8092/$APP_PORT/g" \
    -e "s/3311/$DB_PORT/g" \
    -e "s/DB_NAME=php_framework_app/DB_NAME=$DB_NAME_SAFE/" \
    -e "s/MAILER_FROM_NAME=php-framework-app/MAILER_FROM_NAME=$NAME/" \
    .env.example

echo "==> README.md"
sed -i \
    -e "1s/.*/# $NAME/" \
    -e "3s#.*#Projet independant, forke depuis [\`$SOURCE_PROJECT_NAME\`](https://github.com/$GITHUB_ORG/$SOURCE_PROJECT_NAME), construit sur [\`adrien/php-framework\`](https://github.com/$GITHUB_ORG/php-framework) (dependance Composer \`vcs\`, voir \`composer.json\`).#" \
    -e "s/8092/$APP_PORT/g" \
    README.md

echo "==> templates (navbar + accueil)"
sed -i "s/>$SOURCE_PROJECT_NAME</>$NAME</" templates/layout.html.twig
cat > templates/home/index.html.twig <<TWIG
{% extends 'layout.html.twig' %}

{% block title %}$NAME{% endblock %}

{% block body %}
    <h1>$NAME</h1>
    <p>En construction.</p>
{% endblock %}
TWIG

echo "==> CLAUDE.md (sections Projet + chargement du framework reecrites, ports, fork)"

PROJET_SECTION="## Projet

**$NAME** est un projet independant, forke depuis \`$SOURCE_PROJECT_NAME\` (voir \"Fork\" en bas de ce fichier), construit sur [\`adrien/php-framework\`](https://github.com/$GITHUB_ORG/php-framework), un framework PHP personnel minimaliste (PHP 8.4, MVC en couches strictes, peu de dependances). Ce depot contient le code applicatif (\`src/App/\`, \`templates/\`, config, Docker) ; toute la logique reutilisable (routing, DI, Twig, DBAL, erreurs, plugins, CLI) vit dans la librairie, importee via Composer (repository \`vcs\`, voir ci-dessous).

**Documentation du framework** : si \`php-framework\` est clone en frere sur cette machine, [\`../php-framework/docs/index.html\`](../php-framework/docs/index.html) ; sinon <https://github.com/$GITHUB_ORG/php-framework/tree/main/docs> — a consulter systematiquement avant d'ajouter une feature ici, plutot que de redefinir des conventions."

FRAMEWORK_SECTION="## Comment le framework est charge

\`composer.json\` declare un repository Composer de type \`vcs\` pointant sur le depot git du framework :

\`\`\`json
\"repositories\": [{ \"type\": \"vcs\", \"url\": \"$FRAMEWORK_REMOTE_URL\" }]
\`\`\`

\`vendor/adrien/php-framework\` est donc un **vrai clone git** (branche \`dev-main\`), pas un lien symbolique : contrairement a \`$SOURCE_PROJECT_NAME\`, ce depot ne reflete **pas** automatiquement les modifications locales du dossier \`php-framework\` sur la machine. Pour recuperer une evolution du framework : \`make composer update adrien/php-framework\`.

Le conteneur \`php\` a besoin d'un acces SSH au depot (prive) du framework pour cloner : \`docker-compose.yml\` forwarde l'agent SSH de l'hote (\${SSH_AUTH_SOCK}) plutot que d'embarquer une cle."

{
    awk '/^## Projet/{exit} {print}' CLAUDE.md
    printf '%s\n\n' "$PROJET_SECTION"
    printf '%s\n\n' "$FRAMEWORK_SECTION"
    awk 'f{print} /^## Stack/{f=1; print}' CLAUDE.md
} > CLAUDE.md.new
mv CLAUDE.md.new CLAUDE.md

# Ports locaux (Docker) cite aussi 8092/3311 en toutes lettres dans sa prose.
sed -i -e "s/8092/$APP_PORT/g" -e "s/3311/$DB_PORT/g" CLAUDE.md

cat >> CLAUDE.md <<CLAUDEMD

## Fork depuis $SOURCE_PROJECT_NAME

Ce depot est un fork git de \`$SOURCE_PROJECT_NAME\` (cree via son \`bin/fork-project.sh\`) : historique complet preserve, remote \`upstream\` pointant dessus (fetch-only — \`git push upstream\` echoue volontairement, un push d'ici n'atteint jamais \`$SOURCE_PROJECT_NAME\`).

Recuperer les evolutions en amont, a la demande (jamais automatique) :

\`\`\`bash
git fetch upstream
git merge upstream/main   # ou upstream/\$(git -C ../$SOURCE_PROJECT_NAME branch --show-current)
\`\`\`
CLAUDEMD

echo
echo "==> Termine. Prochaines etapes :"
echo "  1. cd $TARGET_DIR"
echo "  2. cp .env.example .env && editer APP_SECRET"
echo "  3. make install   (composer install doit cloner adrien/php-framework via SSH)"
echo "  4. Creer le depot GitHub prive $GITHUB_ORG/$NAME (vide, sans README auto), puis :"
echo "     git push -u origin main"
