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
    ],

    'database' => [
        'host' => $_ENV['DB_HOST'] ?? 'mariadb',
        'port' => (int) ($_ENV['DB_PORT'] ?? 3306),
        'name' => $_ENV['DB_NAME'] ?? 'app',
        'user' => $_ENV['DB_USER'] ?? 'app',
        'password' => $_ENV['DB_PASSWORD'] ?? '',
    ],

    'paths' => [
        'root' => dirname(__DIR__),
        'var' => dirname(__DIR__) . '/var',
        'templates' => dirname(__DIR__) . '/templates',
        'plugins_registry' => dirname(__DIR__) . '/plugins-registry.json',
        'plugins_installed' => dirname(__DIR__) . '/plugins/installed.json',
    ],
];
