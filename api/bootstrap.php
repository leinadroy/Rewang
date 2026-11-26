<?php
declare(strict_types=1);

// Autoload class dari folder lib/ (tanpa Composer, cocok untuk shared hosting)
spl_autoload_register(function (string $class): void {
    $file = __DIR__ . '/lib/' . $class . '.php';
    if (is_file($file)) {
        require $file;
    }
});

$configFile = __DIR__ . '/config.php';
if (!is_file($configFile)) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => 'config.php belum dibuat. Salin config.example.php menjadi config.php.']);
    exit;
}

Config::load(require $configFile);

date_default_timezone_set(Config::get('app.timezone', 'Asia/Jakarta'));

$debug = (bool) Config::get('app.debug', false);
ini_set('display_errors', '0');
error_reporting(E_ALL);

set_error_handler(function (int $no, string $msg, string $file, int $line): bool {
    throw new ErrorException($msg, 0, $no, $file, $line);
});

set_exception_handler(function (Throwable $e) use ($debug): void {
    error_log((string) $e);
    $payload = ['error' => 'Terjadi kesalahan pada server'];
    if ($debug) {
        $payload['detail'] = $e->getMessage();
        $payload['at'] = basename($e->getFile()) . ':' . $e->getLine();
    }
    Response::json($payload, 500);
});

if (session_status() === PHP_SESSION_NONE) {
    session_name('REWANGSESSID');
    session_set_cookie_params([
        'httponly' => true,
        'samesite' => 'Lax',
        'secure'   => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
    ]);
    session_start();
}
