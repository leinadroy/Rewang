<?php
declare(strict_types=1);

/** @var Router $router */

$router->get('/health', function () {
    $db = 'connected';
    try {
        Database::pdo()->query('SELECT 1');
    } catch (Throwable $e) {
        $db = 'error';
        if (Config::get('app.debug')) {
            $db .= ': ' . $e->getMessage();
        }
    }

    Response::json([
        'status'   => 'ok',
        'database' => $db,
        'php'      => PHP_VERSION,
        'time'     => date('c'),
    ]);
});

// Contoh route dengan parameter:
// $router->get('/users/{id}', function (array $params) {
//     $user = Database::one('SELECT id, name, email FROM users WHERE id = ?', [$params['id']]);
//     $user ? Response::json($user) : Response::error('User tidak ditemukan', 404);
// });
