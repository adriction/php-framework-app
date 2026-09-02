<?php

/**
 * Front controller HTTP : point d'entree unique pour toutes les requetes web
 * (nginx redirige tout vers ce fichier, cf. docker/nginx/default.conf).
 * Framework\Kernel vient de vendor/adrien/php-framework.
 */

require dirname(__DIR__) . '/vendor/autoload.php';

use Framework\Http\Request;
use Framework\Kernel;

$kernel = new Kernel(dirname(__DIR__));
$response = $kernel->handle(Request::fromGlobals());
$response->send();
