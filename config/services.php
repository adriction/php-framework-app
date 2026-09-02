<?php

use Doctrine\DBAL\Connection;
use Framework\Config\Config;
use Framework\Database\ConnectionFactory;
use Framework\Log\FileLogger;
use Framework\Plugin\PluginManager;
use Framework\Routing\Router;
use Framework\View\TwigFactory;
use Psr\Log\LoggerInterface;
use Twig\Environment;

use function DI\autowire;
use function DI\factory;

/**
 * Definitions PHP-DI du conteneur applicatif. Identique dans l'esprit a
 * config/services.php de php-framework lui-meme : PHP-DI autowire tout ce qui
 * n'a pas besoin d'etre construit "a la main" (interfaces, valeurs .env).
 *
 * Toutes les classes Framework\* viennent de vendor/adrien/php-framework.
 */
return [
    Config::class => factory(static fn () => new Config(require __DIR__ . '/app.php')),

    Connection::class => factory(
        static fn (Config $config) => ConnectionFactory::create($config)
    ),

    Environment::class => factory(
        static fn (Config $config) => TwigFactory::create($config)
    ),

    LoggerInterface::class => autowire(FileLogger::class),

    Router::class => autowire(),
    PluginManager::class => autowire(),
];
