<?php
declare(strict_types=1);

// Saat development (php -S), file statis yang benar-benar ada dilayani langsung.
if (PHP_SAPI === 'cli-server') {
    $file = __DIR__ . parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    if ($file !== __FILE__ && is_file($file) && !str_ends_with($file, '.php')) {
        return false;
    }
}

require __DIR__ . '/bootstrap.php';

$router = new Router();
require __DIR__ . '/routes.php';

$router->dispatch($_SERVER['REQUEST_METHOD'], Request::path());
