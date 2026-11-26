<?php
declare(strict_types=1);

final class Request
{
    private static ?array $body = null;

    /**
     * Path relatif terhadap folder api/, mis. "/health".
     * Bekerja di root domain, di subfolder, maupun di php -S saat development.
     */
    public static function path(): string
    {
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

        $base = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
        if ($base !== '' && str_starts_with($path, $base)) {
            $path = substr($path, strlen($base));
        }
        if (preg_match('#^/api(/|$)#', $path)) {
            $path = substr($path, 4);
        }

        $path = '/' . trim($path, '/');
        return $path;
    }

    /** Body JSON (atau form biasa) sebagai array. */
    public static function body(): array
    {
        if (self::$body === null) {
            $type = $_SERVER['CONTENT_TYPE'] ?? '';
            if (str_contains($type, 'application/json')) {
                $decoded = json_decode(file_get_contents('php://input') ?: '', true);
                self::$body = is_array($decoded) ? $decoded : [];
            } else {
                self::$body = $_POST;
            }
        }
        return self::$body;
    }

    public static function input(string $key, mixed $default = null): mixed
    {
        return self::body()[$key] ?? $_GET[$key] ?? $default;
    }
}
