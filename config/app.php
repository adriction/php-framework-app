<?php

/**
 * Configuration applicative, lue par Framework\Config\Config (fourni par
 * adrien/php-framework, cf. vendor/adrien/php-framework/src/Framework/Config).
 * Toutes les valeurs viennent des variables d'environnement (definies dans .env).
 */

return [
    'app' => [
        'env' => $_ENV['APP_ENV'] ?? 'prod',
        'debug' => (bool) ($_ENV['APP_DEBUG'] ?? false),
        'secret' => $_ENV['APP_SECRET'] ?? '',
        // Utilise par la fonction Twig url() (URL absolues, ex. Open Graph/canonical) et par tout code
        // ayant besoin de l'URL publique du site. Volontairement explicite plutot que derive du header
        // Host de la requete, qui peut etre falsifie par le client.
        'url' => $_ENV['APP_URL'] ?? 'http://localhost',
    ],

    'database' => [
        'host' => $_ENV['DB_HOST'] ?? 'mariadb',
        'port' => (int) ($_ENV['DB_PORT'] ?? 3306),
        'name' => $_ENV['DB_NAME'] ?? 'app',
        'user' => $_ENV['DB_USER'] ?? 'app',
        'password' => $_ENV['DB_PASSWORD'] ?? '',
    ],

    'mailer' => [
        'host' => $_ENV['MAILER_HOST'] ?? 'localhost',
        'port' => (int) ($_ENV['MAILER_PORT'] ?? 1025),
        'auth' => (bool) ($_ENV['MAILER_AUTH'] ?? false),
        'username' => $_ENV['MAILER_USERNAME'] ?? '',
        'password' => $_ENV['MAILER_PASSWORD'] ?? '',
        'encryption' => $_ENV['MAILER_ENCRYPTION'] ?? null,
        'from_address' => $_ENV['MAILER_FROM_ADDRESS'] ?? 'no-reply@example.com',
        'from_name' => $_ENV['MAILER_FROM_NAME'] ?? 'php-framework-app',
    ],

    'middleware' => [
        // Middlewares executes sur TOUTES les routes, avant ceux poses via
        // #[Middleware] sur un controleur precis. Voir docs/middlewares.html.
        'global' => [
        ],
    ],

    'assets' => [
        // Bundles CSS/JS construits par "assets:build" (voir docs/assets.html
        // et "assets:init" pour generer une premiere config). Vide par
        // defaut : rien n'est construit tant qu'aucun bundle n'est declare.
        'output_dir' => 'public/build',
        'css' => [
        ],
        'js' => [
        ],
    ],

    'paths' => [
        'root' => dirname(__DIR__),
        'var' => dirname(__DIR__) . '/var',
        'templates' => dirname(__DIR__) . '/templates',
        'plugins_registry' => dirname(__DIR__) . '/plugins-registry.json',
        'plugins_installed' => dirname(__DIR__) . '/plugins/installed.json',
    ],
];
